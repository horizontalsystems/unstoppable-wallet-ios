import Combine
import Foundation
import MarketKit
import SwiftUI

// Entry screen state: recipient token/address/EXACT amount, priced live. The quote is display-only —
// the confirmation step commits its own order.
final class CrossPayViewModel: ObservableObject {
    private static let quoteDebounce: TimeInterval = 0.5

    let wallet: Wallet
    let currency: Currency

    private let service: CrossPayService?
    private let marketKit = Core.shared.marketKit
    private let currencyManager = Core.shared.currencyManager
    private var cancellables = Set<AnyCancellable>()
    private var priceCancellable: AnyCancellable?
    private var quoteTask: Task<Void, Never>?

    var tokenIn: Token { wallet.token }

    let availableBalance: Decimal?

    @Published private(set) var tokenOut: Token?
    // Sheet binding for the token selector; the reset logic runs once in onSelect.
    @Published var selectedTokenOut: Token? {
        didSet {
            if let selectedTokenOut { onSelect(tokenOut: selectedTokenOut) }
        }
    }

    @Published var recipientText: String = ""
    @Published var recipientResult: AddressInput.Result = .idle

    // Amount/fiat mirror as in PreSendViewModel; the amount is entered in the TARGET token.
    @Published private(set) var amount: Decimal? {
        didSet {
            if oldValue != amount {
                let string = AmountDecimalParser.string(from: amount)
                if AmountDecimalParser.parseAnyDecimal(from: amountString) != amount {
                    amountString = string
                }
                syncFiatAmount()
                scheduleQuote()
            }
        }
    }

    @Published var amountString: String = "" {
        didSet {
            var parsed = AmountDecimalParser.parseAnyDecimal(from: amountString)
            if parsed == 0 { parsed = nil }

            // Rounded DOWN to the target token's precision: an over-precise value could never pass
            // the strict exactness check at commit.
            let rounded = parsed.flatMap { value in tokenOut.map { value.roundedDown(decimal: $0.decimals) } } ?? parsed

            guard rounded != amount else { return }

            enteringFiat = false
            amount = rounded
        }
    }

    @Published var fiatAmount: Decimal? {
        didSet {
            let string = AmountDecimalParser.string(from: fiatAmount)
            if AmountDecimalParser.parseAnyDecimal(from: fiatAmountString)?.rounded(decimal: 2) != fiatAmount {
                fiatAmountString = string
            }
            syncAmount()
        }
    }

    @Published var fiatAmountString: String = "" {
        didSet {
            let parsed = AmountDecimalParser.parseAnyDecimal(from: fiatAmountString)?.rounded(decimal: 2)

            guard parsed != fiatAmount else { return }

            enteringFiat = true
            fiatAmount = parsed
        }
    }

    @Published private(set) var coinPrice: CoinPrice? {
        didSet {
            syncFiatAmount()
        }
    }

    private var enteringFiat = false

    @Published private(set) var quoteState: QuoteState?

    init(wallet: Wallet) {
        self.wallet = wallet
        // The Pay button is gated on the service being wired; nil degrades to "token unsupported".
        service = Core.crossPayService
        currency = Core.shared.currencyManager.baseCurrency
        availableBalance = (Core.shared.adapterManager.adapter(for: wallet.token) as? IBalanceAdapter)?.balanceData.available

        // Until the token map lands, any pending quote stays in Loading via the re-schedule below.
        service?.syncAssets()
        service?.assetsSyncPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.scheduleQuote() }
            .store(in: &cancellables)
    }

    var canReview: Bool {
        guard case .valid = recipientResult, case .success = quoteState else { return false }
        return true
    }

    var reviewRequest: CrossPayRequest? {
        guard let tokenOut, let amount, case let .valid(success) = recipientResult else { return nil }

        return CrossPayRequest(
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            recipient: success.address.raw,
            amount: amount
        )
    }
}

extension CrossPayViewModel {
    enum QuoteState {
        case loading
        // What the sender pays in tokenIn for the entered exact output.
        case success(sellAmount: Decimal)
        case error(CrossPayError)
    }
}

private extension CrossPayViewModel {
    func onSelect(tokenOut token: Token) {
        guard tokenOut != token else { return }

        tokenOut = token

        // The amount and recipient belong to the previous token/chain — never carried over.
        enteringFiat = false
        amount = nil
        recipientText = ""
        recipientResult = .idle
        quoteState = nil
        quoteTask?.cancel()

        coinPrice = marketKit.coinPrice(coinUid: token.coin.uid, currencyCode: currency.code)
        priceCancellable = marketKit.coinPricePublisher(coinUid: token.coin.uid, currencyCode: currency.code)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] price in self?.coinPrice = price }
    }

    func syncAmount() {
        guard enteringFiat else { return }

        guard let coinPrice, !coinPrice.expired, coinPrice.value > 0, let fiatAmount, let tokenOut else {
            amount = nil
            return
        }

        amount = (fiatAmount / coinPrice.value).roundedDown(decimal: tokenOut.decimals)
    }

    func syncFiatAmount() {
        guard !enteringFiat else { return }

        guard let coinPrice, !coinPrice.expired, let amount else {
            fiatAmount = nil
            return
        }

        fiatAmount = (amount * coinPrice.value).rounded(decimal: 2)
    }

    func scheduleQuote() {
        quoteTask?.cancel()

        guard let tokenOut, let amount, amount > 0 else {
            quoteState = nil
            return
        }

        guard let service else {
            quoteState = .error(.tokenUnsupported)
            return
        }

        quoteState = .loading

        let tokenIn = tokenIn

        quoteTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Self.quoteDebounce * 1_000_000_000))
            guard !Task.isCancelled else { return }

            // Asset map not landed yet: re-kick the sync (deduped and expiration-guarded in the
            // repository, so a failed fetch gets retried) and stay in Loading until it publishes.
            guard service.supports(token: tokenIn) else {
                service.syncAssets()
                return
            }

            let state: QuoteState

            if !service.supports(tokenIn: tokenIn, tokenOut: tokenOut) {
                state = .error(.tokenUnsupported)
            } else {
                do {
                    let sellAmount = try await service.quote(tokenIn: tokenIn, tokenOut: tokenOut, amountOut: amount)
                    state = .success(sellAmount: sellAmount)
                } catch let error as CrossPayError {
                    state = .error(error)
                } catch {
                    state = .error(.networkError(error))
                }
            }

            guard !Task.isCancelled else { return }

            await MainActor.run { [weak self] in
                self?.quoteState = state
            }
        }
    }
}

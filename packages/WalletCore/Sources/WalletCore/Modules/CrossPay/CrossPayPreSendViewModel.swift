import Combine
import Foundation
import MarketKit

// The Cross Pay tab of PreSendView: the amount and recipient are in the token the RECIPIENT receives,
// priced live in the wallet's token. The quote is display-only — the confirmation screen commits its
// own order, building the deposit transfer from a snapshot of the shared `handler`'s settings taken
// here, on the main thread.
final class CrossPayPreSendViewModel: BasePreSendViewModel {
    private static let quoteDebounce: TimeInterval = 0.5

    private let service: CrossPayService?
    private var quoteTask: Task<Void, Never>?

    @Published private(set) var isSupported: Bool

    // Starts nil: no receive token is preselected.
    @Published private(set) var tokenOut: Token?

    // Sheet binding for the token selector; the reset logic runs once in onSelect.
    @Published var selectedTokenOut: Token? {
        didSet {
            if let selectedTokenOut {
                onSelect(tokenOut: selectedTokenOut)
            }
        }
    }

    @Published private(set) var quoteState: QuoteState? {
        didSet {
            syncSendData()
        }
    }

    override var amount: Decimal? {
        didSet {
            if oldValue != amount {
                scheduleQuote()
            }
        }
    }

    // The predefined address and amount belong to the sending chain and token, never carried over.
    init(wallet: Wallet, handler: IPreSendHandler?, service: CrossPayService?) {
        self.service = service
        isSupported = Self.isSupported(token: wallet.token, service: service)

        // No receive token yet, so no coin price to subscribe to.
        super.init(wallet: wallet, handler: handler, predefinedAddress: nil, amount: nil, initialInputToken: nil)

        // Until the asset map lands the tab stays hidden; a pending quote stays in Loading and is
        // re-scheduled here.
        service?.syncAssets()
        service?.assetsSyncPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.onAssetsSync() }
            .store(in: &cancellables)

        AppStateManager.instance.$swapEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.syncSupported() }
            .store(in: &cancellables)
    }

    deinit {
        quoteTask?.cancel()
    }

    var tokenIn: Token {
        token
    }

    override var inputToken: Token? {
        tokenOut
    }

    override var addressToken: Token? {
        tokenOut
    }

    // The recipient is on the destination chain, so there is no source address to compare against.
    override var addressFromAddress: String? {
        nil
    }

    override var balancePercents: [Int] {
        []
    }

    // The amount is in the receive token, so the sent token's balance cannot fill it.
    override var maxAmountEnabled: Bool {
        false
    }

    // Rounded DOWN to the receive token's precision: an over-precise value could never pass the
    // strict exactness check at commit.
    override func roundedInput(_ amount: Decimal?) -> Decimal? {
        guard let amount, let tokenOut else {
            return amount
        }

        return amount.roundedDown(decimal: tokenOut.decimals)
    }

    override func canConvertFiat(coinPrice: CoinPrice) -> Bool {
        !coinPrice.expired && coinPrice.value > 0
    }

    override func setAmountIn(percent _: Int) {}

    // Never calls `handler.set(address:)`: the shared handler's address-dependent state belongs to the
    // Standard tab, and the deposit address does not exist until the order is committed.
    override func syncSendData() {
        if case let .error(error) = quoteState {
            cautions = [CautionNew(text: error.errorDescription ?? "cross_pay.error.commit_failed".localized, type: .error)]
        } else {
            cautions = []
        }

        guard isSupported, let tokenOut, let amount, amount > 0, let resolvedAddress, case let .success(payAmount) = quoteState else {
            sendData = nil
            return
        }

        if let availableBalance, payAmount > availableBalance {
            sendData = nil
            return
        }

        let request = CrossPayRequest(
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            recipient: resolvedAddress.address,
            amount: amount,
            depositSettings: handler?.depositSettingsSnapshot
        )

        // nil: the handler saves the recipient under the destination chain itself.
        sendData = ExtendedSendData(sendData: .crossPay(request: request), address: nil)
    }

    override var buttonState: PreSendButtonState {
        guard let adapterState, adapterState.isSynced else {
            return super.buttonState
        }

        if tokenOut == nil {
            return PreSendButtonState(title: "cross_pay.select_token".localized, disabled: true, showProgress: false)
        }

        if amount == nil {
            return PreSendButtonState(title: "send.enter_amount".localized, disabled: true, showProgress: false)
        }

        switch quoteState {
        case .loading:
            return PreSendButtonState(title: "cross_pay.quoting".localized, disabled: true, showProgress: true)
        case .error:
            return PreSendButtonState(title: "cross_pay.unavailable".localized, disabled: true, showProgress: false)
        case let .success(payAmount):
            if let availableBalance, payAmount > availableBalance {
                return PreSendButtonState(title: "send.insufficient_balance".localized, disabled: true, showProgress: false)
            }
        case .none:
            ()
        }

        if resolvedAddress == nil {
            return PreSendButtonState(title: "send.address.enter_address".localized, disabled: true, showProgress: false)
        }

        return PreSendButtonState(title: "send.next_button".localized, disabled: sendData == nil, showProgress: false)
    }

    // A nil service yields false permanently, so an app that never wires Cross Pay is unaffected.
    // XRP is rejected by CrossPayHandlerProvider, so the tab must not offer it either.
    static func isSupported(token: Token, service: CrossPayService?) -> Bool {
        guard let service else {
            return false
        }

        guard token.blockchainType != .xrp else {
            return false
        }

        guard PrivateSendHandlerProvider.baseToken(token: token) != nil else {
            return false
        }

        // The payment is funded through the swap rail, so it sits behind the same gate as swapping.
        guard AppStateManager.instance.swapEnabled else {
            return false
        }

        return service.supports(token: token)
    }
}

extension CrossPayPreSendViewModel {
    enum QuoteState: Equatable {
        case loading
        // What the sender pays in tokenIn for the entered exact output.
        case success(payAmount: Decimal)
        case error(CrossPayError)

        static func == (lhs: QuoteState, rhs: QuoteState) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading): return true
            case let (.success(lhsAmount), .success(rhsAmount)): return lhsAmount == rhsAmount
            case let (.error(lhsError), .error(rhsError)): return lhsError.errorDescription == rhsError.errorDescription
            default: return false
            }
        }
    }
}

private extension CrossPayPreSendViewModel {
    func onAssetsSync() {
        syncSupported()

        if quoteState == .loading {
            scheduleQuote()
        }
    }

    func syncSupported() {
        let isSupported = Self.isSupported(token: token, service: service)

        guard isSupported != self.isSupported else {
            return
        }

        self.isSupported = isSupported

        if isSupported {
            syncSendData()
        } else {
            quoteTask?.cancel()
            quoteState = nil
        }
    }

    func onSelect(tokenOut token: Token) {
        guard tokenOut != token else {
            return
        }

        let blockchainChanged = tokenOut?.blockchainType != token.blockchainType

        tokenOut = token

        quoteTask?.cancel()
        quoteState = nil

        // The amount belongs to the previous token, and the recipient to its chain — never carried over.
        clearAmountIn()

        if blockchainChanged {
            set(address: nil)
        }

        subscribeCoinPrice(token: token)
        syncSendData()
    }

    func scheduleQuote() {
        quoteTask?.cancel()

        guard isSupported, let tokenOut, let amount, amount > 0 else {
            quoteState = nil
            return
        }

        guard let service else {
            quoteState = .error(.tokenUnsupported)
            return
        }

        let tokenIn = tokenIn

        guard tokenOut != tokenIn else {
            quoteState = .error(.tokenUnsupported)
            return
        }

        quoteState = .loading

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
                    let payAmount = try await service.quote(tokenIn: tokenIn, tokenOut: tokenOut, amountOut: amount)
                    state = .success(payAmount: payAmount)
                } catch let error as CrossPayError {
                    state = .error(error)
                } catch {
                    state = .error(.networkError(error))
                }
            }

            guard !Task.isCancelled else { return }

            await MainActor.run { [weak self] in
                // The token or amount changed while quoting: this result is stale.
                guard !Task.isCancelled, let self, self.tokenOut == tokenOut, self.amount == amount else {
                    return
                }

                quoteState = state
            }
        }
    }
}

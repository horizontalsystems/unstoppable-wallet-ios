import Combine
import Foundation
import HsExtensions
import MarketKit

class MultiSwapConfirmationViewModel: ObservableObject {
    let quoteExpirationDuration: Int = 10

    private let currencyManager = App.shared.currencyManager
    private let marketKit = App.shared.marketKit
    private let transactionServiceFactory = TransactionServiceFactory()

    private var quoteTask: AnyTask?
    private var timer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    let tokenIn: Token
    let tokenOut: Token
    let amountIn: Decimal
    let provider: IMultiSwapProvider
    let transactionService: ITransactionService?
    let currency: Currency
    let feeToken: Token?

    @Published var transactionSettingsModified = false

    @Published var rateIn: Decimal?
    @Published var rateOut: Decimal?
    @Published var feeTokenRate: Decimal?

    @Published var state: State = .quoting {
        didSet {
            syncPrice()

            timer?.cancel()

            if let quote = state.quote, quote.canSwap {
                quoteTimeLeft = quoteExpirationDuration

                timer = Timer.publish(every: 1, on: .main, in: .common)
                    .autoconnect()
                    .sink { [weak self] _ in
                        self?.handleTimerTick()
                    }
            }
        }
    }

    @Published var quoteTimeLeft: Int = 0

    @Published var price: String?
    private var priceFlipped = false

    @Published var swapping = false

    let errorSubject = PassthroughSubject<String, Never>()

    init(tokenIn: Token, tokenOut: Token, amountIn: Decimal, provider: IMultiSwapProvider) {
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.amountIn = amountIn
        self.provider = provider

        transactionService = transactionServiceFactory.transactionService(blockchainType: tokenIn.blockchainType)

        currency = currencyManager.baseCurrency

        feeToken = try? marketKit.token(query: TokenQuery(blockchainType: tokenIn.blockchainType, tokenType: .native))

        transactionService?.updatePublisher
            .sink { [weak self] in
                self?.syncTransactionSettingsModified()
                self?.syncQuote()
            }
            .store(in: &cancellables)

        if let feeToken {
            feeTokenRate = marketKit.coinPrice(coinUid: feeToken.coin.uid, currencyCode: currency.code)?.value
            marketKit.coinPricePublisher(tag: "swap", coinUid: feeToken.coin.uid, currencyCode: currency.code)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] price in self?.feeTokenRate = price.value }
                .store(in: &cancellables)
        }

        rateIn = marketKit.coinPrice(coinUid: tokenIn.coin.uid, currencyCode: currency.code)?.value
        marketKit.coinPricePublisher(tag: "swap", coinUid: tokenIn.coin.uid, currencyCode: currency.code)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] price in self?.rateIn = price.value }
            .store(in: &cancellables)

        rateOut = marketKit.coinPrice(coinUid: tokenOut.coin.uid, currencyCode: currency.code)?.value
        marketKit.coinPricePublisher(tag: "swap", coinUid: tokenOut.coin.uid, currencyCode: currency.code)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] price in self?.rateOut = price.value }
            .store(in: &cancellables)

        syncQuote()
    }

    private func handleTimerTick() {
        quoteTimeLeft -= 1

        if quoteTimeLeft == 0 {
            timer?.cancel()
        }
    }

    private func syncPrice() {
        if let quote = state.quote {
            let amountOut = quote.amountOut
            var showAsIn = amountIn < amountOut

            if priceFlipped {
                showAsIn.toggle()
            }

            let tokenA = showAsIn ? tokenIn : tokenOut
            let tokenB = showAsIn ? tokenOut : tokenIn
            let amountA = showAsIn ? amountIn : amountOut
            let amountB = showAsIn ? amountOut : amountIn

            let formattedValue = ValueFormatter.instance.formatFull(value: amountB / amountA, decimalCount: tokenB.decimals)
            price = formattedValue.map { "1 \(tokenA.coin.code) = \($0) \(tokenB.coin.code)" }
        } else {
            price = nil
        }
    }

    private func syncTransactionSettingsModified() {
        transactionSettingsModified = transactionService?.modified ?? false
    }

    @MainActor private func set(swapping: Bool) {
        self.swapping = swapping
    }
}

extension MultiSwapConfirmationViewModel {
    func syncQuote() {
        guard let transactionService else {
            return
        }

        quoteTask = nil

        if !state.isQuoting {
            state = .quoting
        }

        quoteTask = Task { [weak self, tokenIn, tokenOut, amountIn, provider, transactionService] in
            var state: State

            do {
                try await transactionService.sync()

                let quote = try await provider.confirmationQuote(
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    amountIn: amountIn,
                    transactionSettings: transactionService.transactionSettings
                )

                state = .success(quote: quote)
            } catch {
                state = .failed(error: error)
            }

            if !Task.isCancelled {
                await MainActor.run { [weak self, state] in
                    self?.state = state
                }
            }
        }
        .erased()
    }

    func flipPrice() {
        priceFlipped.toggle()
        syncPrice()
    }

    func swap() async throws {
        do {
            guard let quote = state.quote else {
                throw SwapError.noQuote
            }

            await set(swapping: true)

            try await provider.swap(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, quote: quote)
        } catch {
            await set(swapping: false)
            errorSubject.send(error.smartDescription)
            throw error
        }
    }
}

extension MultiSwapConfirmationViewModel {
    enum State {
        case quoting
        case success(quote: IMultiSwapConfirmationQuote)
        case failed(error: Error)

        var quote: IMultiSwapConfirmationQuote? {
            switch self {
            case let .success(quote): return quote
            default: return nil
            }
        }

        var isQuoting: Bool {
            switch self {
            case .quoting: return true
            default: return false
            }
        }
    }

    enum SwapError: Error {
        case noQuote
    }
}

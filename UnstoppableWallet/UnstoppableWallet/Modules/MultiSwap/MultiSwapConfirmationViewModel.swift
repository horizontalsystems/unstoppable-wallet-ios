import Combine
import Foundation
import HsExtensions
import MarketKit

class MultiSwapConfirmationViewModel: ObservableObject {
    private let currencyManager = App.shared.currencyManager
    private let marketKit = App.shared.marketKit

    private var rateInCancellable: AnyCancellable?
    private var rateOutCancellable: AnyCancellable?
    private var feeTokenRateCancellable: AnyCancellable?
    private var quoteTask: AnyTask?
    private var swapTask: AnyTask?

    let tokenIn: Token
    let tokenOut: Token
    let amountIn: Decimal
    let provider: IMultiSwapProvider
    let transactionService: IMultiSwapTransactionService
    let currency: Currency
    let feeToken: Token?

    @Published var rateIn: Decimal?
    @Published var rateOut: Decimal?
    @Published var feeTokenRate: Decimal?

    @Published var quote: IMultiSwapQuote? {
        didSet {
            syncPrice()
        }
    }

    @Published var quoting = false

    @Published var price: String?
    private var priceFlipped = false

    @Published var swapping = false
    let finishSubject = PassthroughSubject<Void, Never>()

    init(tokenIn: Token, tokenOut: Token, amountIn: Decimal, provider: IMultiSwapProvider, transactionService: IMultiSwapTransactionService) {
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.amountIn = amountIn
        self.provider = provider
        self.transactionService = transactionService

        currency = currencyManager.baseCurrency

        feeToken = try? marketKit.token(query: TokenQuery(blockchainType: tokenIn.blockchainType, tokenType: .native))

        if let feeToken {
            feeTokenRate = marketKit.coinPrice(coinUid: feeToken.coin.uid, currencyCode: currency.code)?.value
            feeTokenRateCancellable = marketKit.coinPricePublisher(tag: "swap", coinUid: feeToken.coin.uid, currencyCode: currency.code)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] price in self?.feeTokenRate = price.value }
        }

        rateIn = marketKit.coinPrice(coinUid: tokenIn.coin.uid, currencyCode: currency.code)?.value
        rateInCancellable = marketKit.coinPricePublisher(tag: "swap", coinUid: tokenIn.coin.uid, currencyCode: currency.code)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] price in self?.rateIn = price.value }

        rateOut = marketKit.coinPrice(coinUid: tokenOut.coin.uid, currencyCode: currency.code)?.value
        rateOutCancellable = marketKit.coinPricePublisher(tag: "swap", coinUid: tokenOut.coin.uid, currencyCode: currency.code)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] price in self?.rateOut = price.value }

        syncQuote()
    }

    private func syncQuote() {
        quoteTask = nil
        quote = nil

        if !quoting {
            quoting = true
        }

        quoteTask = Task { [weak self, tokenIn, tokenOut, amountIn, provider, transactionService] in
            try await transactionService.sync()

            let transactionSettings = transactionService.transactionSettings
            let quote = try await provider.quote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, transactionSettings: transactionSettings)

            if !Task.isCancelled {
                await MainActor.run { [weak self, quote] in
                    self?.quoting = false
                    self?.quote = quote
                }
            }
        }
        .erased()
    }

    private func syncPrice() {
        if let amountOut = quote?.amountOut {
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
}

extension MultiSwapConfirmationViewModel {
    func flipPrice() {
        priceFlipped.toggle()
        syncPrice()
    }

    func swap() {
        guard let quote else {
            return
        }

        swapping = true

        swapTask = Task { [weak self, tokenIn, tokenOut, amountIn, provider, transactionService] in
            do {
                try await provider.swap(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, quote: quote, transactionSettings: transactionService.transactionSettings)

                await MainActor.run { [weak self] in
                    self?.finishSubject.send()
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.swapping = false
                }
            }
        }
        .erased()
    }
}

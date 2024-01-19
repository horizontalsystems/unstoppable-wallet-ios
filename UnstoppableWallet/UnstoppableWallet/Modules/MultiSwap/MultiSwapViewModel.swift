import Combine
import Foundation
import HsExtensions
import MarketKit

class MultiSwapViewModel: ObservableObject {
    let autoRefreshDuration: Double = 30

    private var cancellables = Set<AnyCancellable>()
    private var quotesTask: AnyTask?
    private var rateInCancellable: AnyCancellable?
    private var rateOutCancellable: AnyCancellable?
    private var timer: Timer?

    private let providers: [IMultiSwapProvider]
    private let currencyManager = App.shared.currencyManager
    private let marketKit = App.shared.marketKit
    private let walletManager = App.shared.walletManager
    private let adapterManager = App.shared.adapterManager

    @Published var currency: Currency

    private var enteringFiat = false

    private var internalTokenIn: Token? {
        didSet {
            guard internalTokenIn != oldValue else {
                return
            }

            if internalTokenIn != tokenIn {
                tokenIn = internalTokenIn
            }

            if let internalTokenIn {
                availableBalance = walletManager.activeWallets.first { $0.token == internalTokenIn }.flatMap { adapterManager.balanceAdapter(for: $0)?.balanceData.available }
                rateIn = marketKit.coinPrice(coinUid: internalTokenIn.coin.uid, currencyCode: currency.code)?.value
                rateInCancellable = marketKit.coinPricePublisher(tag: "swap", coinUid: internalTokenIn.coin.uid, currencyCode: currency.code)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] price in self?.rateIn = price.value }
            } else {
                availableBalance = nil
                rateIn = nil
                rateInCancellable = nil
            }
        }
    }

    @Published var tokenIn: Token? {
        didSet {
            guard internalTokenIn != tokenIn else {
                return
            }

            amountIn = nil
            internalTokenIn = tokenIn
            priceFlipped = false
            internalUserSelectedProviderId = nil

            syncQuotes()
        }
    }

    private var internalTokenOut: Token? {
        didSet {
            guard internalTokenOut != oldValue else {
                return
            }

            if internalTokenOut != tokenOut {
                tokenOut = internalTokenOut
            }

            if let internalTokenOut {
                rateOut = marketKit.coinPrice(coinUid: internalTokenOut.coin.uid, currencyCode: currency.code)?.value
                rateOutCancellable = marketKit.coinPricePublisher(tag: "swap", coinUid: internalTokenOut.coin.uid, currencyCode: currency.code)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] price in self?.rateOut = price.value }
            } else {
                rateOut = nil
                rateOutCancellable = nil
            }
        }
    }

    @Published var tokenOut: Token? {
        didSet {
            guard internalTokenOut != tokenOut else {
                return
            }

            internalTokenOut = tokenOut
            priceFlipped = false
            internalUserSelectedProviderId = nil

            syncQuotes()
        }
    }

    @Published var availableBalance: Decimal?

    @Published var rateIn: Decimal? {
        didSet {
            syncFiatAmountIn()
        }
    }

    private var rateOut: Decimal? {
        didSet {
            syncFiatAmountOut()
        }
    }

    var amountIn: Decimal? {
        didSet {
            internalUserSelectedProviderId = nil

            syncQuotes()
            syncFiatAmountIn()

            let amount = Decimal(string: amountString)

            if amount != amountIn {
                amountString = amountIn?.description ?? ""
            }
        }
    }

    @Published var amountString: String = "" {
        didSet {
            let amount = Decimal(string: amountString)

            guard amount != amountIn else {
                return
            }

            enteringFiat = false

            amountIn = amount
        }
    }

    @Published var fiatAmountIn: Decimal? {
        didSet {
            syncAmountIn()

            let amount = Decimal(string: fiatAmountString)?.rounded(decimal: 2)

            if amount != fiatAmountIn {
                fiatAmountString = fiatAmountIn?.description ?? ""
            }
        }
    }

    @Published var fiatAmountString: String = "" {
        didSet {
            let amount = Decimal(string: fiatAmountString)?.rounded(decimal: 2)

            guard amount != fiatAmountIn else {
                return
            }

            enteringFiat = true

            fiatAmountIn = amount
        }
    }

    @Published var currentQuote: Quote? {
        didSet {
            amountOutString = currentQuote?.quote.amountOut.description
            syncFiatAmountOut()
            syncPrice()
        }
    }

    @Published var bestQuote: Quote?

    private var internalUserSelectedProviderId: String? {
        didSet {
            guard internalUserSelectedProviderId != oldValue else {
                return
            }

            if internalUserSelectedProviderId != userSelectedProviderId {
                userSelectedProviderId = internalUserSelectedProviderId
            }
        }
    }

    @Published var userSelectedProviderId: String? {
        didSet {
            guard userSelectedProviderId != internalUserSelectedProviderId else {
                return
            }

            internalUserSelectedProviderId = userSelectedProviderId
            syncCurrentQuote()
        }
    }

    @Published var quotes: [Quote] = [] {
        didSet {
            bestQuote = quotes.max { $0.quote.amountOut < $1.quote.amountOut }
            syncCurrentQuote()

            timer?.invalidate()
            quoteTimeLeft = 0

            if !quotes.isEmpty {
                quoteTimeLeft = Double(autoRefreshDuration)

                timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    self?.handleTimerTick()
                }
            }
        }
    }

    @Published var amountOutString: String?
    @Published var fiatAmountOutString: String?

    @Published var price: String?
    private var priceFlipped = false

    @Published var loading = false

    @Published var quoteTimerActive = false
    var quoteTimeLeft: Double = 0 {
        didSet {
            let newQuoteTimerActive = quoteTimeLeft > 0

            if quoteTimerActive != newQuoteTimerActive {
                quoteTimerActive = newQuoteTimerActive
            }
        }
    }

    init(providers: [IMultiSwapProvider], token: Token? = nil) {
        self.providers = providers
        currency = currencyManager.baseCurrency

        defer {
            internalTokenIn = token
        }

        currencyManager.$baseCurrency.sink { [weak self] in self?.currency = $0 }.store(in: &cancellables)

        syncFiatAmountIn()
        syncFiatAmountOut()
    }

    private func handleTimerTick() {
        quoteTimeLeft = max(0, quoteTimeLeft - 0.1)

        if quoteTimeLeft == 0 {
            syncQuotes()
        }
    }

    private func syncCurrentQuote() {
        if let internalUserSelectedProviderId {
            currentQuote = quotes.first { $0.provider.id == internalUserSelectedProviderId } ?? bestQuote
        } else {
            currentQuote = bestQuote
        }
    }

    private func syncAmountIn() {
        guard enteringFiat else {
            return
        }

        guard let rateIn, let fiatAmountIn else {
            amountIn = nil
            return
        }

        amountIn = fiatAmountIn / rateIn
    }

    private func syncFiatAmountIn() {
        guard !enteringFiat else {
            return
        }

        guard let rateIn, let amountIn else {
            fiatAmountIn = nil
            return
        }

        fiatAmountIn = (amountIn * rateIn).rounded(decimal: 2)
    }

    private func syncFiatAmountOut() {
        let rateOut = currentQuote != nil ? rateOut : 0

        guard let rateOut else {
            fiatAmountOutString = nil
            return
        }

        let amount = currentQuote?.quote.amountOut ?? 0
        fiatAmountOutString = "\(currency.symbol)\((amount * rateOut).rounded(decimal: 2).description)"
    }

    private func syncQuotes() {
        quotesTask = nil
        quotes = []

        guard let internalTokenIn, let internalTokenOut, let amountIn, amountIn != 0 else {
            if loading {
                loading = false
            }

            return
        }

        let validProviders = providers.filter { $0.supports(tokenIn: internalTokenIn, tokenOut: internalTokenOut) }

        guard !validProviders.isEmpty else {
            if loading {
                loading = false
            }

            return
        }

        if !loading {
            loading = true
        }

        quotesTask = Task { [weak self] in
            let optionalQuotes: [Quote?] = await withTaskGroup(of: Quote?.self) { group in
                for provider in validProviders {
                    group.addTask {
                        do {
                            let quote = try await provider.quote(tokenIn: internalTokenIn, tokenOut: internalTokenOut, amountIn: amountIn)
                            return Quote(provider: provider, quote: quote)
                        } catch {
                            print("QUOTE ERROR: \(provider.id): \(error)")
                            return nil
                        }
                    }
                }

                var quotes = [Quote?]()

                for await quote in group {
                    quotes.append(quote)
                }

                return quotes
            }

            let quotes = optionalQuotes.compactMap { $0 }.sorted { $0.quote.amountOut > $1.quote.amountOut }

            if !Task.isCancelled {
                await MainActor.run { [weak self, quotes] in
                    self?.loading = false
                    self?.quotes = quotes
                }
            }
        }
        .erased()
    }

    private func syncPrice() {
        if let tokenIn, let tokenOut, let amountIn, amountIn != 0, let amountOut = currentQuote?.quote.amountOut {
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

extension MultiSwapViewModel {
    func interchange() {
        let internalTokenIn = internalTokenIn
        self.internalTokenIn = internalTokenOut
        internalTokenOut = internalTokenIn
        amountIn = currentQuote?.quote.amountOut
    }

    func flipPrice() {
        priceFlipped.toggle()
        syncPrice()
    }

    func setAmountIn(percent: Int) {
        guard let availableBalance else {
            return
        }

        amountIn = availableBalance * Decimal(percent) / 100
    }

    func swap() {}
}

extension MultiSwapViewModel {
    struct Quote {
        let provider: IMultiSwapProvider
        let quote: MultiSwapQuote
    }
}

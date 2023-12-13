import Combine
import Foundation
import HsExtensions
import MarketKit

class BuyViewModel: ObservableObject {
    let defaultAmount: Decimal = 100
    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    private let currencyManager = App.shared.currencyManager
    private let marketKit = App.shared.marketKit
    private let rampManager = App.shared.rampManager

    let token: Token

    @Published var currency: Currency {
        didSet {
            if currency != oldValue {
                syncCurrency()
                syncQuotes()
            }
        }
    }

    private var amount: Decimal {
        didSet {
            if amount != oldValue {
                syncQuotes()
            }
        }
    }

    @Published var amountString: String {
        didSet {
            amount = Decimal(string: amountString) ?? 0
        }
    }

    private var rate: Decimal? {
        didSet {
            syncBestQuoteConvertedAmount()
        }
    }

    @Published var quotes: [RampQuote] = []
    @Published var bestQuote: RampQuote?
    @Published var bestQuoteConvertedAmount: Decimal?

    init(token: Token) {
        self.token = token

        currency = currencyManager.baseCurrency
        amountString = defaultAmount.description

        amount = defaultAmount

        syncCurrency()
        syncQuotes()
    }

    private func syncQuotes() {
        tasks.removeAll()
        handle(quotes: [])

        Task { [weak self, rampManager, token, amount, currency] in
            let quotes = await rampManager.quotes(token: token, fiatAmount: amount, currencyCode: currency.code)

            DispatchQueue.main.async { [weak self] in
                self?.handle(quotes: quotes)
            }
        }
        .store(in: &tasks)
    }

    private func handle(quotes: [RampQuote]) {
        self.quotes = quotes
        bestQuote = quotes.sorted { $0.cryptoAmount > $1.cryptoAmount }.first

        syncBestQuoteConvertedAmount()
    }

    private func syncCurrency() {
        cancellables.removeAll()

        marketKit.coinPricePublisher(tag: "buy-view-model", coinUid: token.coin.uid, currencyCode: currency.code)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] price in
                self?.rate = price.value
            }
            .store(in: &cancellables)

        rate = marketKit.coinPrice(coinUid: token.coin.uid, currencyCode: currency.code)?.value
    }

    private func syncBestQuoteConvertedAmount() {
        guard let rate, let bestQuote else {
            bestQuoteConvertedAmount = nil
            return
        }

        bestQuoteConvertedAmount = bestQuote.cryptoAmount * rate
    }
}

extension BuyViewModel {
    var popularCurrencies: [Currency] {
        currencyManager.popularCurrencies
    }

    var otherCurrencies: [Currency] {
        currencyManager.otherCurrencies
    }
}

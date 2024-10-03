import Combine
import Foundation
import HsExtensions
import MarketKit
import RxRelay
import RxSwift

class HistoricalRateService {
    private let marketKit: MarketKit.Kit
    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    private var currency: Currency
    private var rates = [RateKey: CurrencyValue]()

    private let rateUpdatedSubject = PassthroughSubject<(RateKey, CurrencyValue), Never>()
    private let ratesChangedSubject = PassthroughSubject<Void, Never>()

    private let queue = DispatchQueue(label: "\(AppConfig.label).transactions-historical-rate-service-queue", qos: .userInitiated)

    init(marketKit: MarketKit.Kit, currencyManager: CurrencyManager) {
        self.marketKit = marketKit
        currency = currencyManager.baseCurrency

        currencyManager.$baseCurrency
            .sink { [weak self] currency in
                self?.handleUpdated(currency: currency)
            }
            .store(in: &cancellables)
    }

    private func handleUpdated(currency: Currency) {
        tasks = Set()
        ratesChangedSubject.send()

        queue.async {
            self.currency = currency
            self.rates = [:]
        }
    }

    private func handle(key: RateKey, rate: Decimal) {
        queue.async {
            let rate = CurrencyValue(currency: self.currency, value: rate)
            self.rates[key] = rate
            self.rateUpdatedSubject.send((key, rate))
        }
    }

    private func fetch(key: RateKey) {
        Task { [weak self, marketKit, currency] in
            let rate = try await marketKit.coinHistoricalPriceValue(coinUid: key.token.coin.uid, currencyCode: currency.code, timestamp: key.date.timeIntervalSince1970)
            self?.handle(key: key, rate: rate)
        }.store(in: &tasks)
    }
}

extension HistoricalRateService {
    var rateUpdatedPublisher: AnyPublisher<(RateKey, CurrencyValue), Never> {
        rateUpdatedSubject.eraseToAnyPublisher()
    }

    var ratesChangedPublisher: AnyPublisher<Void, Never> {
        ratesChangedSubject.eraseToAnyPublisher()
    }

    func rate(key: RateKey) -> CurrencyValue? {
        queue.sync {
            if let currencyValue = rates[key] {
                return currencyValue
            }

            guard !key.token.isCustom else {
                return nil
            }

            if let value = marketKit.cachedCoinHistoricalPriceValue(coinUid: key.token.coin.uid, currencyCode: currency.code, timestamp: key.date.timeIntervalSince1970) {
                let currencyValue = CurrencyValue(currency: currency, value: value)
                rates[key] = currencyValue
                return currencyValue
            }

            return nil
        }
    }

    func fetchRate(key: RateKey) {
        guard !key.token.isCustom else {
            return
        }

        queue.async {
            if self.rates[key] == nil {
                self.fetch(key: key)
            }
        }
    }
}

struct RateKey: Hashable {
    let token: Token
    let date: Date

    func hash(into hasher: inout Hasher) {
        hasher.combine(token)
        hasher.combine(date)
    }

    static func == (lhs: RateKey, rhs: RateKey) -> Bool {
        lhs.token == rhs.token && lhs.date == rhs.date
    }
}

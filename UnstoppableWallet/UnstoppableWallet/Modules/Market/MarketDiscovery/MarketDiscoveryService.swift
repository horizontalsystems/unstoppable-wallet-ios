import CurrencyKit
import XRatesKit
import Foundation
import RxSwift
import RxRelay

class MarketDiscoveryService {
    private let disposeBag = DisposeBag()
    private var discoveryItemsDisposable: Disposable?

    private let currencyKit: ICurrencyKit
    private let rateManager: IRateManager

    private let categoriesProvider: MarketCategoriesProvider
    var currentCategory: MarketDiscoveryFilter? {
        didSet {
            fetch()
        }
    }

    private let stateRelay = BehaviorRelay<State>(value: .loading)
    var items = [MarketModule.Item]()

    init(currencyKit: ICurrencyKit, rateManager: IRateManager, categoriesProvider: MarketCategoriesProvider) {
        self.currencyKit = currencyKit
        self.rateManager = rateManager
        self.categoriesProvider = categoriesProvider

        fetch()
    }

    private func fetch() {
        discoveryItemsDisposable?.dispose()
        discoveryItemsDisposable = nil

        stateRelay.accept(.loading)

        let single: Single<[CoinMarket]>
        if let category = currentCategory {
            let coinCodes = categoriesProvider.coinCodes(for: category == .rated ? nil : category.rawValue)
            single = rateManager.coinsMarketSingle(currencyCode: currencyKit.baseCurrency.code, coinCodes: coinCodes)
        } else {
            single = rateManager.topMarketsSingle(currencyCode: currencyKit.baseCurrency.code)
        }

        discoveryItemsDisposable = single
                .subscribe(onSuccess: { [weak self] in self?.sync(items: $0) })

        discoveryItemsDisposable?.disposed(by: disposeBag)
    }

    private func sync(items: [CoinMarket]) {
        self.items = items.enumerated().compactMap { (index, coinMarket) in
            let score: MarketModule.Score?
            switch currentCategory {
            case .rated:
                let rate = categoriesProvider.rate(for: coinMarket.coin.code)
                guard !(rate?.isEmpty ?? true) else {
                    return nil
                }

                score = rate.flatMap { $0.isEmpty ? nil : .rating($0) }
            case .none:
                score = .rank(index + 1)
            default:
                score = nil
            }
            return MarketModule.Item(coinMarket: coinMarket, score: score)
        }

        stateRelay.accept(.loaded)
    }

}

extension MarketDiscoveryService {

    public var currency: Currency {
        //todo: refactor to use current currency and handle changing
        currencyKit.currencies.first { $0.code == "USD" } ?? currencyKit.currencies[0]
    }

    public var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    public func refresh() {
        fetch()
    }

}

extension MarketDiscoveryService {

    enum State {
        case loaded
        case loading
        case error(error: Error)
    }

}

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
    var items = [MarketListService.Item]()

    init(currencyKit: ICurrencyKit, rateManager: IRateManager, categoriesProvider: MarketCategoriesProvider) {
        self.currencyKit = currencyKit
        self.rateManager = rateManager
        self.categoriesProvider = categoriesProvider

        fetch()
    }

    private func convertItem(rank: Int, topMarket: CoinMarket) -> MarketListService.Item {
        MarketListService.Item(
            rank: rank,
            coinCode: topMarket.coin.code,
            coinName: topMarket.coin.title,
            coinType: topMarket.coin.type.flatMap { rateManager.convertXRateCoinTypeToCoinType(coinType: $0) },
            marketCap: topMarket.marketInfo.marketCap,
            liquidity: topMarket.marketInfo.liquidity,
            price: topMarket.marketInfo.rate,
            diff: topMarket.marketInfo.rateDiffPeriod,
            volume: topMarket.marketInfo.volume)
    }

    private func fetch() {
        discoveryItemsDisposable?.dispose()
        discoveryItemsDisposable = nil

        stateRelay.accept(.loading)

        let single: Single<[CoinMarket]>
        if let category = currentCategory, category != .rated { //todo: make rated case
            let coinCodes = categoriesProvider.coinCodes(for: category.rawValue)
            single = rateManager.coinsMarketSingle(currencyCode: currencyKit.baseCurrency.code, coinCodes: coinCodes)
        } else {
            single = rateManager.topMarketsSingle(currencyCode: currencyKit.baseCurrency.code)
        }
        discoveryItemsDisposable = single
                .subscribe(onSuccess: { [weak self] in self?.sync(items: $0) })

        discoveryItemsDisposable?.disposed(by: disposeBag)
    }

    private func sync(items: [CoinMarket]) {
        self.items = items.enumerated().map { (index, topMarket) in
            convertItem(rank: index + 1, topMarket: topMarket)
        }

        stateRelay.accept(.loaded)
    }

}

extension MarketDiscoveryService {

    public var currency: Currency {
        currencyKit.baseCurrency
    }

    public var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    public func refresh() {
        fetch()
    }

}

extension MarketDiscoveryService {

    enum Rank {
        case index(Int)
        case score(String)
    }

    enum State {
        case loaded
        case loading
        case error(error: Error)
    }

    struct Item {
        let rank: Int
        let coinCode: String
        let coinName: String
        let coinType: CoinType?
        let marketCap: Decimal
        let liquidity: Decimal?
        let price: Decimal
        let diff: Decimal
        let volume: Decimal
    }

}

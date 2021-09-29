import XRatesKit
import RxSwift
import RxRelay

class MarketDiscoveryService {
    private let rateManager: IRateManager

    private let refetchRelay = PublishRelay<()>()

    private let currentCategoryRelay = PublishRelay<MarketDiscoveryFilter?>()
    var currentCategory: MarketDiscoveryFilter? {
        didSet {
            currentCategoryRelay.accept(currentCategory)
            refetchRelay.accept(())
        }
    }

    init(rateManager: IRateManager) {
        self.rateManager = rateManager
    }

}

extension MarketDiscoveryService: IMarketListFetcher {

    func fetchSingle(currencyCode: String) -> Single<[MarketModule.Item]> {
        if let category = currentCategory {
//            let coinCodes = categoriesProvider.coinCodes(for: category == .rated ? nil : category.rawValue)
            let coinTypes = rateManager.coinTypes(for: category.rawValue)
            return rateManager.coinsMarketSingle(currencyCode: currencyCode, coinTypes: coinTypes)
                    .map { coinMarkets in
                        coinMarkets.compactMap { MarketModule.Item(coinMarket: $0) }
                    }
        } else {
            return rateManager.topMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: .hour24, itemCount: 250)
                    .map { coinMarkets in
                        coinMarkets.compactMap { MarketModule.Item(coinMarket: $0) }
                    }
        }
    }

    var refetchObservable: Observable<()> {
        refetchRelay.asObservable()
    }

}

extension MarketDiscoveryService {

    var currentCategoryObservable: Observable<MarketDiscoveryFilter?> {
        currentCategoryRelay.asObservable()
    }

}

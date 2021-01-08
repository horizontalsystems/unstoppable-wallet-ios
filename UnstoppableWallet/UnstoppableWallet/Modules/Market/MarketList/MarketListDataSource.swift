import RxSwift
import XRatesKit

protocol IMarketListDataSource {
    var dataUpdatedAsync: Observable<()> { get }
    func itemsSingle(currencyCode: String, period: MarketListDataSource.Period) -> Single<[MarketListDataSource.Item]>
}

class MarketTopDataSource {
    private let rateManager: IRateManager
    private let factory: MarketDataSourceFactory

    init(rateManager: IRateManager, factory: MarketDataSourceFactory) {
        self.rateManager = rateManager
        self.factory = factory
    }

}

extension MarketTopDataSource: IMarketListDataSource {

    var dataUpdatedAsync: Observable<()> {
        Observable.empty()
    }

    func itemsSingle(currencyCode: String, period: MarketListDataSource.Period) -> Single<[MarketListDataSource.Item]> {
        rateManager
            .topMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: factory.marketListPeriod(period: period))
            .map { topMarkets in
                topMarkets.enumerated().compactMap { [weak self] (index, topMarket) in
                    self?.factory.marketListItem(rank: index + 1, topMarket: topMarket)
                }
            }
    }

}

class MarketDefiDataSource {
    private let rateManager: IRateManager
    private let factory: MarketDataSourceFactory

    init(rateManager: IRateManager, factory: MarketDataSourceFactory) {
        self.rateManager = rateManager
        self.factory = factory
    }

}

extension MarketDefiDataSource: IMarketListDataSource {

    var dataUpdatedAsync: Observable<()> {
        Observable.empty()
    }

    func itemsSingle(currencyCode: String, period: MarketListDataSource.Period) -> Single<[MarketListDataSource.Item]> {
        rateManager
            .topDefiMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: factory.marketListPeriod(period: period))
            .map { topMarkets in
                topMarkets.enumerated().compactMap { [weak self] (index, topMarket) in
                    self?.factory.marketListItem(rank: index + 1, topMarket: topMarket)
                }
            }
    }

}

class MarketListDataSource {

    enum Period: Int, CaseIterable {
        case hour
        case dayStart
        case day
        case week
        case month
        case year
    }

    struct Item {
        let rank: Int
        let coinCode: String
        let coinName: String
        let marketCap: Decimal
        let price: Decimal
        let diff: Decimal
        let volume: Decimal
    }

}

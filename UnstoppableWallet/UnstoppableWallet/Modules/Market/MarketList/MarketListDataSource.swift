import RxSwift
import RxRelay
import XRatesKit

protocol IMarketListDataSource {
    var periods: [MarketListDataSource.Period] { get }
    var sortingFields: [MarketListDataSource.SortingField] { get }

    var dataUpdatedObservable: Observable<()> { get }
    func itemsSingle(currencyCode: String, period: MarketListDataSource.Period) -> Single<[CoinMarket]>
}

extension IMarketListDataSource {

    var periods: [MarketListDataSource.Period] {
        MarketListDataSource.Period.allCases
    }

}

class MarketTopDataSource {
    private let rateManager: IRateManager
    private let factory: MarketDataSourceFactory
    private let dataUpdatedRelay = PublishRelay<()>()

    init(rateManager: IRateManager, factory: MarketDataSourceFactory) {
        self.rateManager = rateManager
        self.factory = factory
    }

}

extension MarketTopDataSource: IMarketListDataSource {

    var sortingFields: [MarketListDataSource.SortingField] {
        [.highestCap, .lowestCap, .highestVolume, .lowestVolume, .highestPrice, .lowestPrice, .topGainers, .topLoosers]
    }

    var dataUpdatedObservable: Observable<()> {
        dataUpdatedRelay.asObservable()
    }

    public func itemsSingle(currencyCode: String, period: MarketListDataSource.Period) -> Single<[CoinMarket]> {
        rateManager.topMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: factory.marketListPeriod(period: period))
    }

}

class MarketDefiDataSource {
    private let rateManager: IRateManager
    private let factory: MarketDataSourceFactory
    private let dataUpdatedRelay = PublishRelay<()>()

    init(rateManager: IRateManager, factory: MarketDataSourceFactory) {
        self.rateManager = rateManager
        self.factory = factory
    }

}

extension MarketDefiDataSource: IMarketListDataSource {

    var sortingFields: [MarketListDataSource.SortingField] {
        [.highestLiquidity, .lowestLiquidity, .highestVolume, .lowestVolume, .highestPrice, .lowestPrice, .topGainers, .topLoosers]
    }

    var dataUpdatedObservable: Observable<()> {
        dataUpdatedRelay.asObservable()
    }

    public func itemsSingle(currencyCode: String, period: MarketListDataSource.Period) -> Single<[CoinMarket]> {
        rateManager.topDefiMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: factory.marketListPeriod(period: period))
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

    enum SortingField: Int, CaseIterable {
        case highestCap
        case lowestCap
        case highestLiquidity
        case lowestLiquidity
        case highestVolume
        case lowestVolume
        case highestPrice
        case lowestPrice
        case topGainers
        case topLoosers
    }

}

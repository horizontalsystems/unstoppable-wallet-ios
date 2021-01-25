import RxSwift
import RxRelay
import XRatesKit

protocol IMarketListDataSource {
    var sortingFields: [MarketListDataSource.SortingField] { get }

    var dataUpdatedObservable: Observable<()> { get }
    func itemsSingle(currencyCode: String) -> Single<[CoinMarket]>
}

class MarketTopDataSource {
    private let rateManager: IRateManager
    private let dataUpdatedRelay = PublishRelay<()>()

    init(rateManager: IRateManager) {
        self.rateManager = rateManager
    }

}

extension MarketTopDataSource: IMarketListDataSource {

    var sortingFields: [MarketListDataSource.SortingField] {
        [.highestCap, .lowestCap, .highestVolume, .lowestVolume, .highestPrice, .lowestPrice, .topGainers, .topLoosers]
    }

    var dataUpdatedObservable: Observable<()> {
        dataUpdatedRelay.asObservable()
    }

    public func itemsSingle(currencyCode: String) -> Single<[CoinMarket]> {
        rateManager.topMarketsSingle(currencyCode: currencyCode)
    }

}

class MarketDefiDataSource {
    private let rateManager: IRateManager
    private let dataUpdatedRelay = PublishRelay<()>()

    init(rateManager: IRateManager) {
        self.rateManager = rateManager
    }

}

extension MarketDefiDataSource: IMarketListDataSource {

    var sortingFields: [MarketListDataSource.SortingField] {
        [.highestLiquidity, .lowestLiquidity, .highestVolume, .lowestVolume, .highestPrice, .lowestPrice, .topGainers, .topLoosers]
    }

    var dataUpdatedObservable: Observable<()> {
        dataUpdatedRelay.asObservable()
    }

    public func itemsSingle(currencyCode: String) -> Single<[CoinMarket]> {
        rateManager.topDefiMarketsSingle(currencyCode: currencyCode)
    }

}

class MarketListDataSource {

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

import RxSwift
import RxRelay
import XRatesKit

protocol IMarketListDataSource {
    var sortingFields: [MarketListDataSource.SortingField] { get }

    var dataUpdatedObservable: Observable<()> { get }
    func itemsSingle(currencyCode: String) -> Single<[CoinMarket]>
}

extension IMarketListDataSource {

    var sortingFields: [MarketListDataSource.SortingField] {
        [.highestCap, .lowestCap, .highestVolume, .lowestVolume, .highestPrice, .lowestPrice, .topGainers, .topLoosers]
    }

}

class MarketListDataSource {
    private let rateManager: IRateManager
    private let dataUpdatedRelay = PublishRelay<()>()

    init(rateManager: IRateManager) {
        self.rateManager = rateManager
    }

}

extension MarketListDataSource: IMarketListDataSource {

    var dataUpdatedObservable: Observable<()> {
        dataUpdatedRelay.asObservable()
    }

    public func itemsSingle(currencyCode: String) -> Single<[CoinMarket]> {
        rateManager.topMarketsSingle(currencyCode: currencyCode)
    }

}

class MarketWatchlistDataSource {
    private let disposeBag = DisposeBag()
    private let rateManager: IRateManager
    private let favoritesManager: IFavoritesManager

    private let dataUpdatedRelay = PublishRelay<()>()

    init(rateManager: IRateManager, favoritesManager: IFavoritesManager) {
        self.rateManager = rateManager
        self.favoritesManager = favoritesManager

        subscribe(disposeBag, favoritesManager.dataUpdatedObservable) { [weak self] in
            self?.dataUpdatedRelay.accept(())
        }
    }

}

extension MarketWatchlistDataSource: IMarketListDataSource {

    var dataUpdatedObservable: Observable<()> {
        dataUpdatedRelay.asObservable()
    }

    public func itemsSingle(currencyCode: String) -> Single<[CoinMarket]> {
        rateManager.coinsMarketSingle(currencyCode: currencyCode, coinCodes: favoritesManager.all.map { $0.coinCode })
    }

}

extension MarketListDataSource {

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

import XRatesKit
import RxSwift
import RxRelay

class MarketWatchlistService {
    private let rateManager: IRateManager
    private let favoritesManager: IFavoritesManager
    private let disposeBag = DisposeBag()

    private let refetchRelay = PublishRelay<()>()

    init(rateManager: IRateManager, favoritesManager: IFavoritesManager) {
        self.rateManager = rateManager
        self.favoritesManager = favoritesManager

        subscribe(disposeBag, favoritesManager.dataUpdatedObservable) { [weak self] in
            self?.refetchRelay.accept(())
        }
    }

}

extension MarketWatchlistService: IMarketListFetcher {

    func fetchSingle(currencyCode: String) -> Single<[MarketModule.Item]> {
        let coinCodes = favoritesManager.all.map { $0.coinCode }

        return rateManager.coinsMarketSingle(currencyCode: currencyCode, coinCodes: coinCodes)
                .map { coinMarkets in
                    coinMarkets.map { coinMarket in
                        MarketModule.Item(coinMarket: coinMarket)
                    }
                }
    }

    var refetchObservable: Observable<()> {
        refetchRelay.asObservable()
    }

}

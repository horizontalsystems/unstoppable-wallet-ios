import RxSwift
import XRatesKit

class RateListInteractor {
    weak var delegate: IRateListInteractorDelegate?

    private let rateManager: IRateManager
    private let walletManager: IWalletManager
    private let appConfigProvider: IAppConfigProvider
    private let postsManager: IPostsManager

    private let disposeBag = DisposeBag()

    init(rateManager: IRateManager, walletManager: IWalletManager, appConfigProvider: IAppConfigProvider, postsManager: IPostsManager) {
        self.rateManager = rateManager
        self.walletManager = walletManager
        self.appConfigProvider = appConfigProvider
        self.postsManager = postsManager
    }

}

extension RateListInteractor: IRateListInteractor {

    var wallets: [Wallet] {
        walletManager.wallets
    }

    var featuredCoins: [Coin] {
        appConfigProvider.featuredCoins
    }

    func marketInfo(coinCode: CoinCode, currencyCode: String) -> MarketInfo? {
        rateManager.marketInfo(coinCode: coinCode, currencyCode: currencyCode)
    }

    func subscribeToMarketInfos(currencyCode: String) {
        rateManager.marketInfosObservable(currencyCode: currencyCode)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] marketInfos in
                    self?.delegate?.didReceive(marketInfos: marketInfos)
                })
                .disposed(by: disposeBag)
    }

    func posts(coinCode: CoinCode, timestamp: TimeInterval) -> [CryptoNewsPost]? {
        postsManager.posts(coinCode: coinCode, timestamp: timestamp)
    }

    func subscribeToPosts(coinCode: CoinCode) {
        postsManager.subscribeToPosts(coinCode: coinCode)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] posts in
                    self?.delegate?.didReceive(posts: posts)
                })
                .disposed(by: disposeBag)
    }

}

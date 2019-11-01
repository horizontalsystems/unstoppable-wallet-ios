import RxSwift
import XRatesKit

class RateListInteractor {
    private let disposeBag = DisposeBag()
    weak var delegate: IRateListInteractorDelegate?

    private let rateManager: IXRateManager
    private let currencyManager: ICurrencyManager
    private let walletManager: IWalletManager
    private let appConfigProvider: IAppConfigProvider

    init(rateManager: IXRateManager, currencyManager: ICurrencyManager, walletManager: IWalletManager, appConfigProvider: IAppConfigProvider) {
        self.rateManager = rateManager
        self.currencyManager = currencyManager
        self.walletManager = walletManager
        self.appConfigProvider = appConfigProvider
    }

}

extension RateListInteractor: IRateListInteractor {

    var currency: Currency {
        currencyManager.baseCurrency
    }

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

}

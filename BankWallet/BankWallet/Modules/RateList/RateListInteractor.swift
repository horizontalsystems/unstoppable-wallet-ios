import RxSwift
import XRatesKit

class RateListInteractor {
    private let disposeBag = DisposeBag()
    weak var delegate: IRateListInteractorDelegate?

    private let rateManager: IXRateManager
    private let currencyManager: ICurrencyManager
    private let walletManager: IWalletManager
    private let appConfigProvider: IAppConfigProvider
    private let rateListSorter: IRateListSorter

    init(rateManager: IXRateManager, currencyManager: ICurrencyManager, walletManager: IWalletManager, appConfigProvider: IAppConfigProvider, rateListSorter: IRateListSorter) {
        self.rateManager = rateManager
        self.currencyManager = currencyManager
        self.walletManager = walletManager
        self.appConfigProvider = appConfigProvider
        self.rateListSorter = rateListSorter
    }

}

extension RateListInteractor: IRateListInteractor {

    var currency: Currency {
        currencyManager.baseCurrency
    }

    var coins: [Coin] {
        rateListSorter.smartSort(for: walletManager.wallets.map { $0.coin }, featuredCoins: appConfigProvider.featuredCoins)
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

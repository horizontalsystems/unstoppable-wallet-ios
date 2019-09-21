import RxSwift

class RateListInteractor {
    private let disposeBag = DisposeBag()
    weak var delegate: IRateListInteractorDelegate?

    private let rateStatsManager: IRateStatsManager
    private let appManager: IAppManager
    private let rateStorage: IRateStorage
    private let currencyManager: ICurrencyManager
    private let walletManager: IWalletManager
    private let appConfigProvider: IAppConfigProvider
    private let rateListSorter: IRateListSorter
    private let currentDateProvider: ICurrentDateProvider

    init(rateStatsManager: IRateStatsManager, appManager: IAppManager, currencyManager: ICurrencyManager, walletManager: IWalletManager, rateStorage: IRateStorage, appConfigProvider: IAppConfigProvider, rateListSorter: IRateListSorter, currentDateProvider: ICurrentDateProvider) {
        self.rateStatsManager = rateStatsManager
        self.appManager = appManager
        self.rateStorage = rateStorage
        self.currentDateProvider = currentDateProvider
        self.currencyManager = currencyManager
        self.walletManager = walletManager
        self.appConfigProvider = appConfigProvider
        self.rateListSorter = rateListSorter

        rateStatsManager.statsObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    switch $0 {
                    case .success(let data):
                        self?.delegate?.didReceive(chartData: data)
                    case .error(let coinCode):
                        self?.delegate?.didFailStats(for: coinCode)
                    }
                })
                .disposed(by: disposeBag)
        appManager.willEnterForegroundObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.delegate?.didBecomeActive()
                })
                .disposed(by: disposeBag)
    }

}

extension RateListInteractor: IRateListInteractor {

    var currency: Currency {
        return currencyManager.baseCurrency
    }

    var coins: [Coin] {
        return rateListSorter.smartSort(for: walletManager.wallets.map { $0.coin }, featuredCoins: appConfigProvider.featuredCoins)
    }

    var currentDate: Date {
        return currentDateProvider.currentDate
    }

    func fetchRates(currencyCode: String, coinCodes: [CoinCode]) {
        for coinCode in coinCodes {
            rateStorage.latestRateObservable(forCoinCode: coinCode, currencyCode: currencyCode)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] rate in
                        self?.delegate?.didUpdate(rate: rate)
                    })
                    .disposed(by: disposeBag)
        }
    }

    func getRateStats(currencyCode: String, coinCodes: [CoinCode]) {
        for coinCode in coinCodes {
            rateStatsManager.syncStats(coinCode: coinCode, currencyCode: currencyCode)
        }
    }

}

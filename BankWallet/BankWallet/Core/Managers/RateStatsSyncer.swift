import RxSwift

class RateStatsSyncer {
    private let disposeBag = DisposeBag()
    private var ratesDisposeBag = DisposeBag()

    var balanceStatsOn: Bool = false {
        didSet {
            syncStats()
        }
    }
    var chartShown: Bool = false {
        didSet {
            syncStats()
        }
    }
    var lockStatsOn: Bool = false {
        didSet {
            syncStats()
        }
    }

    private let walletsManager: IWalletManager
    private let currencyManager: ICurrencyManager
    private let rateStatsManager: IRateStatsManager
    private let rateStorage: IRateStorage

    init(walletsManager: IWalletManager, currencyManager: ICurrencyManager, rateStatsManager: IRateStatsManager, rateStorage: IRateStorage) {
        self.walletsManager = walletsManager
        self.currencyManager = currencyManager
        self.rateStatsManager = rateStatsManager
        self.rateStorage = rateStorage

        currencyManager.baseCurrencyUpdatedSignal
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.syncStats()
                    self?.subscribeToRates()
                })
                .disposed(by: disposeBag)
        walletsManager.walletsUpdatedSignal
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.syncStats()
                    self?.subscribeToRates()
                })
                .disposed(by: disposeBag)
    }

    private func syncStats(coinCode: CoinCode, currencyCode: String) {
        if balanceStatsOn || chartShown || lockStatsOn {
            rateStatsManager.syncStats(coinCode: coinCode, currencyCode: currencyCode)
        }
    }

    private func subscribeToRates() {
        ratesDisposeBag = DisposeBag()

        let coinCodes = walletsManager.wallets.map {
            return $0.coin.code
        }
        let currencyCode = currencyManager.baseCurrency.code
        for coinCode in coinCodes {
            rateStorage.latestRateObservable(forCoinCode: coinCode, currencyCode: currencyCode)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] rate in
                        self?.syncStats(coinCode: coinCode, currencyCode: currencyCode)
                    })
                    .disposed(by: ratesDisposeBag)
        }
    }

}

extension RateStatsSyncer: IRateStatsSyncer {

    func syncStats() {
        let currencyCode = currencyManager.baseCurrency.code
        walletsManager.wallets.forEach { wallet in
            syncStats(coinCode: wallet.coin.code, currencyCode: currencyCode)
        }
    }

}

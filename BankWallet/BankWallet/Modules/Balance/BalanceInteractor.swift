import RxSwift

class BalanceInteractor {
    weak var delegate: IBalanceInteractorDelegate?

    private var disposeBag = DisposeBag()
    private var ratesDisposeBag = DisposeBag()
    private var adaptersDisposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let rateStatsManager: IRateStatsManager
    private let rateStorage: IRateStorage
    private let currencyManager: ICurrencyManager
    private let localStorage: ILocalStorage
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager
    private let rateManager: IRateManager
    private let appManager: IAppManager

    init(walletManager: IWalletManager, adapterManager: IAdapterManager, rateStatsManager: IRateStatsManager, rateStorage: IRateStorage, currencyManager: ICurrencyManager, localStorage: ILocalStorage, predefinedAccountTypeManager: IPredefinedAccountTypeManager, rateManager: IRateManager, appManager: IAppManager) {
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.rateStatsManager = rateStatsManager
        self.rateStorage = rateStorage
        self.currencyManager = currencyManager
        self.localStorage = localStorage
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
        self.rateManager = rateManager
        self.appManager = appManager
    }

    private func onUpdateWallets() {
        delegate?.didUpdate(wallets: walletManager.wallets)

        adaptersDisposeBag = DisposeBag()

        for wallet in walletManager.wallets {
            guard let adapter = adapterManager.balanceAdapter(for: wallet) else {
                continue
            }

            delegate?.didUpdate(balance: adapter.balance, wallet: wallet)
            delegate?.didUpdate(state: adapter.state, wallet: wallet)

            adapter.balanceUpdatedObservable
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] in
                        self?.delegate?.didUpdate(balance: adapter.balance, wallet: wallet)
                    })
                    .disposed(by: adaptersDisposeBag)

            adapter.stateUpdatedObservable
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] in
                        self?.delegate?.didUpdate(state: adapter.state, wallet: wallet)
                    })
                    .disposed(by: adaptersDisposeBag)
        }
    }

    private func onUpdateCurrency() {
        delegate?.didUpdate(currency: currencyManager.baseCurrency)
    }

}

extension BalanceInteractor: IBalanceInteractor {

    var sortType: BalanceSortType {
        return localStorage.balanceSortType ?? .name
    }

    func adapter(for wallet: Wallet) -> IBalanceAdapter? {
        return adapterManager.balanceAdapter(for: wallet)
    }

    func initWallets() {
        onUpdateWallets()
        onUpdateCurrency()

        walletManager.walletsUpdatedSignal
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateWallets()
                })
                .disposed(by: disposeBag)

        adapterManager.adaptersReadySignal
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateWallets()
                })
                .disposed(by: disposeBag)

        currencyManager.baseCurrencyUpdatedSignal
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateCurrency()
                })
                .disposed(by: disposeBag)

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

        appManager.didBecomeActiveObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.delegate?.didBecomeActive()
                })
                .disposed(by: disposeBag)
    }

    func fetchRates(currencyCode: String, coinCodes: [CoinCode]) {
        ratesDisposeBag = DisposeBag()

        for coinCode in coinCodes {
            rateStorage.latestRateObservable(forCoinCode: coinCode, currencyCode: currencyCode)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] rate in
                        self?.delegate?.didUpdate(rate: rate)
                    })
                    .disposed(by: ratesDisposeBag)
        }
    }

    func refresh() {
        adapterManager.refresh()
        rateManager.syncLatestRates()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.delegate?.didRefresh()
        }
    }

    func predefinedAccountType(wallet: Wallet) -> IPredefinedAccountType? {
        return predefinedAccountTypeManager.predefinedAccountType(accountType: wallet.account.type)
    }

    func syncStats(coinCode: CoinCode, currencyCode: String) {
        rateStatsManager.syncStats(coinCode: coinCode, currencyCode: currencyCode)
    }

}

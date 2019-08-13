import RxSwift

class BalanceInteractor {
    weak var delegate: IBalanceInteractorDelegate?

    private var disposeBag = DisposeBag()
    private var ratesDisposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let rateStorage: IRateStorage
    private let currencyManager: ICurrencyManager
    private let localStorage: ILocalStorage

    init(walletManager: IWalletManager, adapterManager: IAdapterManager, rateStorage: IRateStorage, currencyManager: ICurrencyManager, localStorage: ILocalStorage) {
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.rateStorage = rateStorage
        self.currencyManager = currencyManager
        self.localStorage = localStorage
    }

    private func onUpdateWallets() {
        delegate?.didUpdate(wallets: walletManager.wallets)
        for wallet in walletManager.wallets {
            guard let adapter = adapterManager.adapter(for: wallet) else {
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
                    .disposed(by: disposeBag)

            adapter.stateUpdatedObservable
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] in
                        self?.delegate?.didUpdate(state: adapter.state, wallet: wallet)
                    })
                    .disposed(by: disposeBag)
        }
    }

    private func onUpdateCurrency() {
        delegate?.didUpdate(currency: currencyManager.baseCurrency)
    }

}

extension BalanceInteractor: IBalanceInteractor {

    var sortType: BalanceSortType {
        return localStorage.balanceSortType ?? .manual
    }

    func adapter(for wallet: Wallet) -> IAdapter? {
        return adapterManager.adapter(for: wallet)
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

        adapterManager.adaptersCreationSignal
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateWallets()
                })
                .disposed(by: disposeBag)

        currencyManager.baseCurrencyUpdatedSignal
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateCurrency()
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.delegate?.didRefresh()
        }
    }

}

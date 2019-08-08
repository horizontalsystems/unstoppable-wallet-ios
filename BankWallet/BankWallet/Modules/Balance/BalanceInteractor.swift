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

        adapterManager.adapterCreationObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] wallet in
                    self?.onUpdateWallet(wallet: wallet)
                })
                .disposed(by: disposeBag)
    }

    private func onUpdateWallets() {
        delegate?.didUpdate(wallets: walletManager.wallets)
        walletManager.wallets.forEach { self.onUpdateWallet(wallet: $0) }
    }

    private func onUpdateWallet(wallet: Wallet) {
        guard let adapter = adapterManager.adapter(for: wallet) else {
            return
        }

        delegate?.didUpdate(balance: adapter.balance, coinCode: wallet.coin.code)
        delegate?.didUpdate(state: adapter.state, coinCode: wallet.coin.code)

        adapter.balanceUpdatedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.delegate?.didUpdate(balance: adapter.balance, coinCode: wallet.coin.code)
                })
                .disposed(by: disposeBag)

        adapter.stateUpdatedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.delegate?.didUpdate(state: adapter.state, coinCode: wallet.coin.code)
                })
                .disposed(by: disposeBag)
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
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
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

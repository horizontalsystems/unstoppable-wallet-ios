import RxSwift

class BalanceInteractor {
    weak var delegate: IBalanceInteractorDelegate?

    private let disposeBag = DisposeBag()
    private var walletsDisposeBag = DisposeBag()
    private var ratesDisposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let rateStorage: IRateStorage
    private let currencyManager: ICurrencyManager

    init(walletManager: IWalletManager, rateStorage: IRateStorage, currencyManager: ICurrencyManager) {
        self.walletManager = walletManager
        self.rateStorage = rateStorage
        self.currencyManager = currencyManager
    }

    private func onUpdateWallets() {
        walletsDisposeBag = DisposeBag()

        let wallets = walletManager.wallets

        delegate?.didUpdate(wallets: wallets)

        for wallet in wallets {
            onUpdateBalance(wallet: wallet)
            onUpdateState(wallet: wallet)

            wallet.adapter.balanceUpdatedSignal
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] in
                        self?.onUpdateBalance(wallet: wallet)
                    })
                    .disposed(by: walletsDisposeBag)

            wallet.adapter.stateUpdatedSignal
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] in
                        self?.onUpdateState(wallet: wallet)
                    })
                    .disposed(by: walletsDisposeBag)
        }
    }

    private func onUpdateCurrency() {
        delegate?.didUpdate(currency: currencyManager.baseCurrency)
    }

    private func onUpdateBalance(wallet: Wallet) {
        delegate?.didUpdate(balance: wallet.adapter.balance, coinCode: wallet.coinCode)
    }

    private func onUpdateState(wallet: Wallet) {
        delegate?.didUpdate(state: wallet.adapter.state, coinCode: wallet.coinCode)
    }

}

extension BalanceInteractor: IBalanceInteractor {

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

    func refresh(coinCode: CoinCode) {
        guard let wallet = walletManager.wallets.first(where: { $0.coinCode == coinCode }) else {
            return
        }

        wallet.adapter.refresh()
    }

}

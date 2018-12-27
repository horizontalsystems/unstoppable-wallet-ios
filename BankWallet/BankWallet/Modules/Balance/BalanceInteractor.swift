import RxSwift

class BalanceInteractor {
    weak var delegate: IBalanceInteractorDelegate?

    private let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)

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

    private func onUpdate(wallets: [Wallet]) {
        walletsDisposeBag = DisposeBag()

        delegate?.didUpdate(wallets: wallets)

        for wallet in wallets {
            wallet.adapter.balanceObservable
                    .subscribeOn(scheduler)
                    .observeOn(scheduler)
                    .subscribe(onNext: { [weak self] balance in
                        self?.delegate?.didUpdate(balance: balance, coinCode: wallet.coinCode)
                    })
                    .disposed(by: walletsDisposeBag)

            wallet.adapter.stateObservable
                    .subscribeOn(scheduler)
                    .observeOn(scheduler)
                    .subscribe(onNext: { [weak self] state in
                        self?.delegate?.didUpdate(state: state, coinCode: wallet.coinCode)
                    })
                    .disposed(by: walletsDisposeBag)
        }
    }

}

extension BalanceInteractor: IBalanceInteractor {

    func initWallets() {
        walletManager.walletsObservable
                .subscribeOn(scheduler)
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] wallets in
                    self?.onUpdate(wallets: wallets)
                })
                .disposed(by: disposeBag)

        currencyManager.baseCurrencyObservable
                .subscribeOn(scheduler)
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] currency in
                    self?.delegate?.didUpdate(currency: currency)
                })
                .disposed(by: disposeBag)
    }

    func fetchRates(currencyCode: String, coinCodes: [CoinCode]) {
        ratesDisposeBag = DisposeBag()

        for coinCode in coinCodes {
            rateStorage.rateObservable(forCoinCode: coinCode, currencyCode: currencyCode)
                    .subscribeOn(scheduler)
                    .observeOn(scheduler)
                    .subscribe(onNext: { rate in
                        self.delegate?.didUpdate(rate: rate)
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

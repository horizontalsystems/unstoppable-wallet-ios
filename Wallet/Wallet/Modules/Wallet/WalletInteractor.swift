import RxSwift

class WalletInteractor {

    weak var delegate: IWalletInteractorDelegate?

    private let disposeBag = DisposeBag()
    private var secondaryDisposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let exchangeRateManager: IExchangeRateManager

    init(walletManager: IWalletManager, exchangeRateManager: IExchangeRateManager) {
        self.walletManager = walletManager
        self.exchangeRateManager = exchangeRateManager
    }

}

extension WalletInteractor: IWalletInteractor {

    func refresh() {
        walletManager.refreshWallets()
    }

    func notifyWalletBalances() {
//        walletManager.subject
//                .subscribe(onNext: { [weak self] in
//                    self?.secondaryDisposeBag = DisposeBag()
//                    self?.initialFetchAndSubscribe()
//                })
//                .disposed(by: disposeBag)

        initialFetchAndSubscribe()
    }

    private func initialFetchAndSubscribe() {
        var coinValues = [String: CoinValue]()
        var progressSubjects = [String: BehaviorSubject<Double>]()

        for wallet in walletManager.wallets {
            coinValues[wallet.coin] = CoinValue(coin: wallet.coin, value: wallet.adapter.balance)
            progressSubjects[wallet.coin] = wallet.adapter.progressSubject
        }

        let rates = exchangeRateManager.exchangeRates

        delegate?.didInitialFetch(coinValues: coinValues, rates: rates, progressSubjects: progressSubjects, currency: DollarCurrency())

        for wallet in walletManager.wallets {
            wallet.adapter.balanceSubject
                    .subscribe(onNext: { [weak self] value in
                        self?.delegate?.didUpdate(coinValue: CoinValue(coin: wallet.coin, value: value))
                    })
                    .disposed(by: secondaryDisposeBag)
        }

        exchangeRateManager.subject
                .subscribe(onNext: { [weak self] rates in
                    self?.delegate?.didUpdate(rates: rates)
                })
                .disposed(by: secondaryDisposeBag)
    }

}

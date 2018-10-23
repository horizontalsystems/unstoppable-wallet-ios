import RxSwift

class WalletInteractor {
    weak var delegate: IWalletInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let exchangeRateManager: IExchangeRateManager

    private let refreshTimeout: Double

    init(walletManager: IWalletManager, exchangeRateManager: IExchangeRateManager, refreshTimeout: Double = 2) {
        self.walletManager = walletManager
        self.exchangeRateManager = exchangeRateManager
        self.refreshTimeout = refreshTimeout

        for wallet in walletManager.wallets {
            wallet.adapter.balanceSubject
                    .subscribe(onNext: { [weak self] value in
                        self?.delegate?.didUpdate(coinValue: CoinValue(coin: wallet.coin, value: value))
                    })
                    .disposed(by: disposeBag)
        }

        exchangeRateManager.subject
                .subscribe(onNext: { [weak self] rates in
                    self?.delegate?.didUpdate(rates: rates)
                })
                .disposed(by: disposeBag)
    }

}

extension WalletInteractor: IWalletInteractor {

    var coinValues: [CoinValue] {
        return walletManager.wallets.map { wallet in
            CoinValue(coin: wallet.coin, value: wallet.adapter.balance)
        }
    }

    var rates: [Coin: CurrencyValue] {
        return exchangeRateManager.exchangeRates
    }

    var progressSubjects: [Coin: BehaviorSubject<Double>] {
        return walletManager.wallets.reduce([Coin: BehaviorSubject<Double>]()) { result, wallet in
            var result = result
            result[wallet.coin] = wallet.adapter.progressSubject
            return result
        }
    }

    func refresh() {
        walletManager.refreshWallets()

        DispatchQueue.main.asyncAfter(deadline: .now() + refreshTimeout) {
            self.delegate?.didRefresh()
        }
    }

}

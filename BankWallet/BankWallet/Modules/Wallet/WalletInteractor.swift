import RxSwift

class WalletInteractor {
    weak var delegate: IWalletInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let rateManager: IRateManager
    private let currencyManager: ICurrencyManager

    private let refreshTimeout: Double

    init(walletManager: IWalletManager, rateManager: IRateManager, currencyManager: ICurrencyManager, refreshTimeout: Double = 2) {
        self.walletManager = walletManager
        self.rateManager = rateManager
        self.currencyManager = currencyManager

        self.refreshTimeout = refreshTimeout

        for wallet in walletManager.wallets {
            wallet.adapter.balanceSubject
                    .subscribe(onNext: { [weak self] _ in
                        self?.delegate?.didUpdate()
                    })
                    .disposed(by: disposeBag)
        }

        rateManager.subject
                .subscribe(onNext: { [weak self] in
                    self?.delegate?.didUpdate()
                })
                .disposed(by: disposeBag)

        currencyManager.subject
                .subscribe(onNext: { [weak self] _ in
                    self?.delegate?.didUpdate()
                })
                .disposed(by: disposeBag)
    }

}

extension WalletInteractor: IWalletInteractor {

    var baseCurrency: Currency {
        return currencyManager.baseCurrency
    }

    var coinValues: [CoinValue] {
        return walletManager.wallets.map { wallet in
            CoinValue(coin: wallet.coin, value: wallet.adapter.balance)
        }
    }

    func rate(forCoin coin: Coin) -> Rate? {
        return rateManager.rate(forCoin: coin, currencyCode: currencyManager.baseCurrency.code)
    }

    func progressSubject(forCoin coin: Coin) -> BehaviorSubject<Double>? {
        guard let wallet = walletManager.wallets.first(where: { $0.coin == coin }) else {
            return nil
        }

        return wallet.adapter.progressSubject
    }

    func refresh() {
        walletManager.refreshWallets()

        DispatchQueue.main.asyncAfter(deadline: .now() + refreshTimeout) {
            self.delegate?.didRefresh()
        }
    }

}

import RxSwift

class BalanceInteractor {
    weak var delegate: IBalanceInteractorDelegate?

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

            wallet.adapter.stateSubject
                    .observeOn(MainScheduler.instance)
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

extension BalanceInteractor: IBalanceInteractor {

    var baseCurrency: Currency {
        return currencyManager.baseCurrency
    }

    var wallets: [Wallet] {
        return walletManager.wallets
    }

    func rate(forCoin coin: Coin) -> Rate? {
        return rateManager.rate(forCoin: coin, currencyCode: currencyManager.baseCurrency.code)
    }

    func refresh(coin: Coin) {
        guard let wallet = walletManager.wallets.first(where: { $0.coin == coin }) else {
            return
        }

        wallet.adapter.refresh()
    }

}

import RxSwift

class ManageWalletsInteractor {
    weak var delegate: IManageWalletsInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let coinManager: ICoinManager
    private let walletManager: IWalletManager
    private let accountManager: IAccountManager
    private let derivationSettingsManager: IDerivationSettingsManager

    init(coinManager: ICoinManager, walletManager: IWalletManager, accountManager: IAccountManager, derivationSettingsManager: IDerivationSettingsManager) {
        self.coinManager = coinManager
        self.walletManager = walletManager
        self.accountManager = accountManager
        self.derivationSettingsManager = derivationSettingsManager

        accountManager.accountsObservable
                .subscribeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.delegate?.didUpdateAccounts()
                })
                .disposed(by: disposeBag)

        coinManager.coinAddedObservable
                .subscribeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.delegate?.didAddCoin()
                })
                .disposed(by: disposeBag)
    }

}

extension ManageWalletsInteractor: IManageWalletsInteractor {

    var coins: [Coin] {
        coinManager.coins
    }

    var featuredCoins: [Coin] {
        coinManager.featuredCoins
    }

    var accounts: [Account] {
        accountManager.accounts
    }

    var wallets: [Wallet] {
        walletManager.wallets
    }

    func save(wallet: Wallet) {
        walletManager.save(wallets: [wallet])
    }

    func delete(wallet: Wallet) {
        walletManager.delete(wallets: [wallet])
    }

    func derivationSetting(coinType: CoinType) -> DerivationSetting? {
        derivationSettingsManager.setting(coinType: coinType)
    }

    func save(derivationSetting: DerivationSetting) {
        derivationSettingsManager.save(setting: derivationSetting)
    }

}

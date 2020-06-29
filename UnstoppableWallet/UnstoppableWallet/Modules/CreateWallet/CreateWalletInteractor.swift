class CreateWalletInteractor {
    private let coinManager: ICoinManager
    private let accountCreator: IAccountCreator
    private let accountManager: IAccountManager
    private let walletManager: IWalletManager
    private let derivationSettingsManager: IDerivationSettingsManager

    init(coinManager: ICoinManager, accountCreator: IAccountCreator, accountManager: IAccountManager, walletManager: IWalletManager, derivationSettingsManager: IDerivationSettingsManager) {
        self.coinManager = coinManager
        self.accountCreator = accountCreator
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.derivationSettingsManager = derivationSettingsManager
    }

}

extension CreateWalletInteractor: ICreateWalletInteractor {

    var coins: [Coin] {
        coinManager.coins
    }

    var featuredCoins: [Coin] {
        coinManager.featuredCoins
    }

    func account(predefinedAccountType: PredefinedAccountType) throws -> Account {
        try accountCreator.newAccount(predefinedAccountType: predefinedAccountType)
    }

    func create(accounts: [Account]) {
        for account in accounts {
            accountManager.save(account: account)
        }
    }

    func resetDerivationSettings() {
        derivationSettingsManager.reset()
    }

    func save(wallets: [Wallet]) {
        walletManager.save(wallets: wallets)
    }

    func derivationSettings(coin: Coin) -> DerivationSetting? {
        derivationSettingsManager.setting(coinType: coin.type)
    }

}

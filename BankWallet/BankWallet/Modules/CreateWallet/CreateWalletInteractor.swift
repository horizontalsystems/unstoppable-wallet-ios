class CreateWalletInteractor {
    private let appConfigProvider: IAppConfigProvider
    private let accountCreator: IAccountCreator
    private let accountManager: IAccountManager
    private let walletManager: IWalletManager
    private let derivationSettingsManager: IDerivationSettingsManager

    init(appConfigProvider: IAppConfigProvider, accountCreator: IAccountCreator, accountManager: IAccountManager, walletManager: IWalletManager, derivationSettingsManager: IDerivationSettingsManager) {
        self.appConfigProvider = appConfigProvider
        self.accountCreator = accountCreator
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.derivationSettingsManager = derivationSettingsManager
    }

}

extension CreateWalletInteractor: ICreateWalletInteractor {

    var coins: [Coin] {
        appConfigProvider.coins
    }

    var featuredCoins: [Coin] {
        appConfigProvider.featuredCoins
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

}

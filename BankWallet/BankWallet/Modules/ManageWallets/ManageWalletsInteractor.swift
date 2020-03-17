class ManageWalletsInteractor {
    weak var delegate: IManageWalletsInteractorDelegate?

    private let appConfigProvider: IAppConfigProvider
    private let walletManager: IWalletManager
    private let walletFactory: IWalletFactory
    private let accountManager: IAccountManager
    private let accountCreator: IAccountCreator
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager
    private let coinSettingsManager: IBlockchainSettingsManager

    init(appConfigProvider: IAppConfigProvider, walletManager: IWalletManager, walletFactory: IWalletFactory, accountManager: IAccountManager, accountCreator: IAccountCreator, predefinedAccountTypeManager: IPredefinedAccountTypeManager, coinSettingsManager: IBlockchainSettingsManager) {
        self.appConfigProvider = appConfigProvider
        self.walletManager = walletManager
        self.walletFactory = walletFactory
        self.accountManager = accountManager
        self.accountCreator = accountCreator
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
        self.coinSettingsManager = coinSettingsManager
    }

}

extension ManageWalletsInteractor: IManageWalletsInteractor {

    var coins: [Coin] {
        appConfigProvider.coins
    }

    var featuredCoins: [Coin] {
        appConfigProvider.featuredCoins
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

    func save(settings: [BlockchainSetting]) {
        coinSettingsManager.save(settings: settings)
    }

    func delete(wallet: Wallet) {
        walletManager.delete(wallets: [wallet])
    }

    func createAccount(predefinedAccountType: PredefinedAccountType) throws -> Account {
        try accountCreator.newAccount(predefinedAccountType: predefinedAccountType)
    }

    func createRestoredAccount(accountType: AccountType) -> Account {
        accountCreator.restoredAccount(accountType: accountType)
    }

    func save(account: Account) {
        accountManager.save(account: account)
    }

    func settings(coinType: CoinType) -> BlockchainSetting? {
        coinSettingsManager.settings(coinType: coinType)
    }

}

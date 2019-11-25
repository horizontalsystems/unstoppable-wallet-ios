class ManageWalletsInteractor {
    weak var delegate: IManageWalletsInteractorDelegate?

    private let appConfigProvider: IAppConfigProvider
    private let walletManager: IWalletManager
    private let walletFactory: IWalletFactory
    private let accountCreator: IAccountCreator
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager
    private let coinSettingsManager: ICoinSettingsManager

    init(appConfigProvider: IAppConfigProvider, walletManager: IWalletManager, walletFactory: IWalletFactory, accountCreator: IAccountCreator, predefinedAccountTypeManager: IPredefinedAccountTypeManager, coinSettingsManager: ICoinSettingsManager) {
        self.appConfigProvider = appConfigProvider
        self.walletManager = walletManager
        self.walletFactory = walletFactory
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
        App.shared.accountManager.accounts
    }

    var wallets: [Wallet] {
        walletManager.wallets
    }

    func wallet(coin: Coin) -> Wallet? {
        walletManager.wallet(coin: coin)
    }

    func save(wallet: Wallet) {
        walletManager.save(wallets: [wallet])
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

    func createWallet(coin: Coin, account: Account) -> Wallet {
        walletFactory.wallet(coin: coin, account: account, coinSettings: [:])
    }

    func coinSettingsToRequest(coin: Coin, accountOrigin: AccountOrigin) -> CoinSettings {
        coinSettingsManager.coinSettingsToRequest(coin: coin, accountOrigin: accountOrigin)
    }

    func coinSettingsToSave(coin: Coin, accountOrigin: AccountOrigin, requestedCoinSettings: CoinSettings) -> CoinSettings {
        coinSettingsManager.coinSettingsToSave(coin: coin, accountOrigin: accountOrigin, requestedCoinSettings: requestedCoinSettings)
    }

}

class RestoreCoinsInteractor {
    private let appConfigProvider: IAppConfigProvider
    private let accountCreator: IAccountCreator
    private let accountManager: IAccountManager
    private let walletManager: IWalletManager
    private let coinSettingsManager: ICoinSettingsManager

    init(appConfigProvider: IAppConfigProvider, accountCreator: IAccountCreator, accountManager: IAccountManager, walletManager: IWalletManager, coinSettingsManager: ICoinSettingsManager) {
        self.appConfigProvider = appConfigProvider
        self.accountCreator = accountCreator
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.coinSettingsManager = coinSettingsManager
    }

}

extension RestoreCoinsInteractor: IRestoreCoinsInteractor {

    var coins: [Coin] {
        appConfigProvider.coins
    }

    var featuredCoins: [Coin] {
        appConfigProvider.featuredCoins
    }

    func account(accountType: AccountType) -> Account {
        accountCreator.restoredAccount(accountType: accountType)
    }

    func create(account: Account) {
        accountManager.save(account: account)
    }

    func save(wallets: [Wallet]) {
        walletManager.save(wallets: wallets)
    }

    func coinSettingsToRequest(coin: Coin, accountOrigin: AccountOrigin) -> CoinSettings {
        coinSettingsManager.coinSettingsToRequest(coin: coin, accountOrigin: accountOrigin)
    }

    func coinSettingsToSave(coin: Coin, accountOrigin: AccountOrigin, requestedCoinSettings: CoinSettings) -> CoinSettings {
        coinSettingsManager.coinSettingsToSave(coin: coin, accountOrigin: accountOrigin, requestedCoinSettings: requestedCoinSettings)
    }

}

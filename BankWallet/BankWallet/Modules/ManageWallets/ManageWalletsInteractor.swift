class ManageWalletsInteractor {
    weak var delegate: IManageWalletsInteractorDelegate?

    private let appConfigProvider: IAppConfigProvider
    private let walletManager: IWalletManager
    private let walletFactory: IWalletFactory
    private let accountCreator: IAccountCreator

    init(appConfigProvider: IAppConfigProvider, walletManager: IWalletManager, walletFactory: IWalletFactory, accountCreator: IAccountCreator) {
        self.appConfigProvider = appConfigProvider
        self.walletManager = walletManager
        self.walletFactory = walletFactory
        self.accountCreator = accountCreator
    }

}

extension ManageWalletsInteractor: IManageWalletsInteractor {

    var coins: [Coin] {
        return appConfigProvider.coins
    }

    var wallets: [Wallet] {
        return walletManager.wallets
    }

    func wallet(coin: Coin) -> Wallet? {
        return walletManager.wallet(coin: coin)
    }

    func enable(wallets: [Wallet]) {
        walletManager.enable(wallets: wallets)
    }

    func createAccount(defaultAccountType: DefaultAccountType) throws -> Account {
        return try accountCreator.createNewAccount(defaultAccountType: defaultAccountType, createDefaultWallets: false)
    }

    func createRestoredAccount(accountType: AccountType, defaultSyncMode: SyncMode?) -> Account {
        return accountCreator.createRestoredAccount(accountType: accountType, defaultSyncMode: defaultSyncMode, createDefaultWallets: false)
    }

    func createWallet(coin: Coin, account: Account) -> Wallet {
        return walletFactory.wallet(coin: coin, account: account, syncMode: account.defaultSyncMode)
    }

}

import RxSwift

class ManageWalletsInteractor {
    weak var delegate: IManageWalletsInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let appConfigProvider: IAppConfigProvider
    private let walletManager: IWalletManager
    private let accountManager: IAccountManager
    private let storage: IEnabledWalletStorage

    init(appConfigProvider: IAppConfigProvider, walletManager: IWalletManager, accountManager: IAccountManager, storage: IEnabledWalletStorage) {
        self.appConfigProvider = appConfigProvider
        self.walletManager = walletManager
        self.accountManager = accountManager
        self.storage = storage
    }

}

extension ManageWalletsInteractor: IManageWalletsInteractor {

    func load() {
        delegate?.didLoad(coins: appConfigProvider.coins, wallets: walletManager.wallets)
    }

    func save(wallets: [Wallet]) {
        var enabledWallets = [EnabledWallet]()

        for (order, wallet) in wallets.enumerated() {
            enabledWallets.append(EnabledWallet(coinCode: wallet.coin.code, accountName: wallet.account.name, syncMode: wallet.syncMode, order: order))
        }

        storage.save(enabledWallets: enabledWallets)
        delegate?.didSaveWallets()
    }

    func accounts(coinType: CoinType) -> [Account] {
        return accountManager.accounts.filter { account in
            return coinType.canSupport(accountType: account.type)
        }
    }

}

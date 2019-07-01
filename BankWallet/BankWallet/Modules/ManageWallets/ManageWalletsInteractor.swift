import RxSwift

class ManageWalletsInteractor {
    weak var delegate: IManageWalletsInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let appConfigProvider: IAppConfigProvider
    private let walletManager: IWalletManager
    private let accountManager: IAccountManager

    init(appConfigProvider: IAppConfigProvider, walletManager: IWalletManager, accountManager: IAccountManager) {
        self.appConfigProvider = appConfigProvider
        self.walletManager = walletManager
        self.accountManager = accountManager
    }

}

extension ManageWalletsInteractor: IManageWalletsInteractor {

    func load() {
        delegate?.didLoad(coins: appConfigProvider.coins, wallets: walletManager.wallets)
    }

    func save(wallets: [Wallet]) {
        walletManager.enable(wallets: wallets)
        delegate?.didSaveWallets()
    }

    func accounts(coinType: CoinType) -> [Account] {
        return accountManager.accounts.filter { account in
            return coinType.canSupport(accountType: account.type)
        }
    }

}

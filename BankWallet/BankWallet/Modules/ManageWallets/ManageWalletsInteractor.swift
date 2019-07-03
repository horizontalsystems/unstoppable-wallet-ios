import RxSwift

class ManageWalletsInteractor {
    weak var delegate: IManageWalletsInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let appConfigProvider: IAppConfigProvider
    private let walletManager: IWalletManager
    private let accountManager: IAccountManager
    private let walletFactory = ManageWalletsWalletFactory()

    init(appConfigProvider: IAppConfigProvider, walletManager: IWalletManager, accountManager: IAccountManager) {
        self.appConfigProvider = appConfigProvider
        self.walletManager = walletManager
        self.accountManager = accountManager
    }

}

extension ManageWalletsInteractor: IManageWalletsInteractor {

    var coins: [Coin] {
        return appConfigProvider.coins
    }

    var wallets: [Wallet] {
        return walletManager.wallets
    }

    var accounts: [Account] {
        return accountManager.accounts
    }

    func save(wallets: [Wallet]) {
        walletManager.enable(wallets: wallets)
    }

    func wallet(coin: Coin) -> Wallet? {
        return walletFactory.wallet(coin: coin, accounts: accountManager.accounts)
    }

}

extension ManageWalletsInteractor: ICreateAccountDelegate {

    func onCreate(account: Account, coin: Coin) {
        delegate?.enable(wallet: walletFactory.wallet(coin: coin, account: account))
    }

}

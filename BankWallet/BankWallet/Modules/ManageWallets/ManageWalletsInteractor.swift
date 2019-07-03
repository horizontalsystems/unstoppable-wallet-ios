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


}

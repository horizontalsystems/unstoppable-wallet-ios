class ManageWalletsPresenter {
    weak var view: IManageWalletsView?

    private let router: IManageWalletsRouter
    private let appConfigProvider: IAppConfigProvider
    private let walletManager: IWalletManager
    private let walletCreator: IWalletCreator
    private let accountCreator: IAccountCreator
    private let stateHandler = ManageWalletsStateHandler()

    private var selectedCoin: Coin?

    private var wallets: [Wallet] = [] {
        didSet {
            coins = stateHandler.remainingCoins(allCoins: appConfigProvider.coins, wallets: wallets)
        }
    }
    private var coins: [Coin] = []

    init(router: IManageWalletsRouter, appConfigProvider: IAppConfigProvider, walletManager: IWalletManager, walletCreator: IWalletCreator, accountCreator: IAccountCreator) {
        self.router = router
        self.appConfigProvider = appConfigProvider
        self.walletManager = walletManager
        self.walletCreator = walletCreator
        self.accountCreator = accountCreator
    }

}

extension ManageWalletsPresenter: IManageWalletsViewDelegate {

    func viewDidLoad() {
        wallets = walletManager.wallets
    }

    func enableCoin(atIndex index: Int) {
        let coin = coins[index]

        if let wallet = walletCreator.wallet(coin: coin) {
            wallets.append(wallet)
            view?.updateUI()
        } else {
            selectedCoin = coin
            view?.showCreateAccount(coin: coin, showNew: coin.type.canCreateAccount)
        }
    }

    func disableWallet(atIndex index: Int) {
        wallets.remove(at: index)
        view?.updateUI()
    }

    func moveWallet(from fromIndex: Int, to toIndex: Int) {
        wallets.insert(wallets.remove(at: fromIndex), at: toIndex)
        view?.updateUI()
    }

    func saveChanges() {
        walletManager.enable(wallets: wallets)
        router.close()
    }

    var walletsCount: Int {
        return wallets.count
    }

    var coinsCount: Int {
        return coins.count
    }

    func wallet(forIndex index: Int) -> Wallet {
        return wallets[index]
    }

    func coin(forIndex index: Int) -> Coin {
        return coins[index]
    }

    func onClose() {
        router.close()
    }

    func didSelectNew() {
        guard let coin = selectedCoin else { return }

        do {
            let account = try accountCreator.createNewAccount(type: coin.type.predefinedAccountType)

            wallets.append(walletCreator.wallet(coin: coin, account: account))
            view?.updateUI()
        } catch {
            view?.show(error: error)
        }
    }

    func didSelectRestore() {
        guard let coin = selectedCoin else { return }

        router.showRestore(type: coin.type.predefinedAccountType, delegate: self)
    }

}

extension ManageWalletsPresenter: IRestoreDelegate {

    func didRestore(accountType: AccountType, syncMode: SyncMode?) {
        guard let coin = selectedCoin else { return }

        let account = accountCreator.createRestoredAccount(accountType: accountType, syncMode: syncMode)

        wallets.append(walletCreator.wallet(coin: coin, account: account))
        view?.updateUI()
    }

}

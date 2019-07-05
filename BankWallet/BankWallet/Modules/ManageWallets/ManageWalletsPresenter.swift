class ManageWalletsPresenter {
    weak var view: IManageWalletsView?

    private let interactor: IManageWalletsInteractor
    private let router: IManageWalletsRouter
    private let stateHandler = ManageWalletsStateHandler()

    private var wallets: [Wallet] = [] {
        didSet {
            coins = stateHandler.remainingCoins(allCoins: interactor.coins, wallets: wallets)
        }
    }
    private var coins: [Coin] = []

    init(interactor: IManageWalletsInteractor, router: IManageWalletsRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension ManageWalletsPresenter: IManageWalletsInteractorDelegate {
}

extension ManageWalletsPresenter: IManageWalletsViewDelegate {

    func viewDidLoad() {
        wallets = interactor.wallets
    }

    func enableCoin(atIndex index: Int) {
        let coin = coins[index]

        if let wallet = interactor.wallet(coin: coin) {
            wallets.append(wallet)
            view?.updateUI()
        } else {
            router.showCreateAccount(coin: coin, delegate: self)
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
        interactor.save(wallets: wallets)
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

}

extension ManageWalletsPresenter: ICreateAccountDelegate {

    func onCreate(account: Account, coin: Coin) {
        let wallet = interactor.wallet(coin: coin, account: account)
        wallets.append(wallet)
        view?.updateUI()
    }

}

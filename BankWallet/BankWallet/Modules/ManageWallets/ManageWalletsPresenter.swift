class ManageWalletsPresenter {
    private let interactor: IManageWalletsInteractor
    private let router: IManageWalletsRouter
    private var state: IManageWalletsPresenterState

    weak var view: IManageWalletsView?

    init(interactor: IManageWalletsInteractor, router: IManageWalletsRouter, state: IManageWalletsPresenterState) {
        self.interactor = interactor
        self.router = router
        self.state = state
    }

}

extension ManageWalletsPresenter: IManageWalletsInteractorDelegate {

    func didLoad(coins: [Coin], wallets: [Wallet]) {
        state.allCoins = coins
        state.wallets = wallets
    }

    func didSaveWallets() {
        router.close()
    }

    func didFailToSaveWallets() {
        view?.show(error: "manage_wallets.fail_to_save")
    }

}

extension ManageWalletsPresenter: IManageWalletsViewDelegate {

    func viewDidLoad() {
        interactor.load()
    }

    func enableCoin(atIndex index: Int) {
        let coin = state.coins[index]
        let suitableAccounts = interactor.accounts(coinType: coin.type)

        guard let account = suitableAccounts.first else {
            return
        }

        state.enable(wallet: Wallet(coin: coin, account: account, syncMode: account.defaultSyncMode))
        view?.updateUI()
    }

    func disableWallet(atIndex index: Int) {
        state.disable(index: index)
        view?.updateUI()
    }

    func moveWallet(from fromIndex: Int, to toIndex: Int) {
        state.move(from: fromIndex, to: toIndex)
        view?.updateUI()
    }

    func saveChanges() {
        interactor.save(wallets: state.wallets)
    }

    var walletsCount: Int {
        get {
            return state.wallets.count
        }
    }

    var coinsCount: Int {
        get {
            return state.coins.count
        }
    }

    func wallet(forIndex index: Int) -> Wallet {
        return state.wallets[index]
    }

    func coin(forIndex index: Int) -> Coin {
        return state.coins[index]
    }

    func onClose() {
        router.close()
    }

}

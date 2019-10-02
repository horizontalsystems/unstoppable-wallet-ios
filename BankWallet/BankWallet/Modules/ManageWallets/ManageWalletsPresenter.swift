class ManageWalletsPresenter {
    private let popularCoinIds = ["BTC", "BCH", "ETH", "DASH", "EOS", "BNB"]

    weak var view: IManageWalletsView?

    private let interactor: IManageWalletsInteractor
    private let router: IManageWalletsRouter

    private var popularItems = [ManageWalletItem]()
    private var items = [ManageWalletItem]()

    private var currentItem: ManageWalletItem?

    init(interactor: IManageWalletsInteractor, router: IManageWalletsRouter) {
        self.interactor = interactor
        self.router = router
    }

    private func viewItem(item: ManageWalletItem) -> ManageWalletViewItem {
        return ManageWalletViewItem(coin: item.coin, enabled: item.wallet != nil)
    }

    private func enable(item: ManageWalletItem) {
        if let wallet = interactor.wallet(coin: item.coin) {
            item.wallet = wallet
        } else if let predefinedAccountType = interactor.predefinedAccountType(coin: item.coin) {
            currentItem = item
            view?.showNoAccount(coin: item.coin, predefinedAccountType: predefinedAccountType)
        }
    }

}

extension ManageWalletsPresenter: IManageWalletsViewDelegate {

    func viewDidLoad() {
        let wallets = interactor.wallets

        let popularCoins = interactor.coins.filter { popularCoinIds.contains($0.id) }
        let coins = interactor.coins.filter { !popularCoinIds.contains($0.id) }

        popularItems = popularCoins.map { coin in
            ManageWalletItem(coin: coin, wallet: wallets.first(where: { $0.coin == coin }))
        }

        items = coins.map { coin in
            ManageWalletItem(coin: coin, wallet: wallets.first(where: { $0.coin == coin }))
        }
    }

    var popularItemsCount: Int {
        return popularItems.count
    }

    func popularItem(index: Int) -> ManageWalletViewItem {
        return viewItem(item: popularItems[index])
    }

    var itemsCount: Int {
        return items.count
    }

    func item(index: Int) -> ManageWalletViewItem {
        return viewItem(item: items[index])
    }

    func enablePopularItem(index: Int) {
        enable(item: popularItems[index])
    }

    func disablePopularItem(index: Int) {
        popularItems[index].wallet = nil
    }

    func enableItem(index: Int) {
        enable(item: items[index])
    }

    func disableItem(index: Int) {
        items[index].wallet = nil
    }

    func saveChanges() {
        let wallets = (popularItems + items).compactMap { $0.wallet }
        interactor.enable(wallets: wallets)
        router.close()
    }

    func close() {
        router.close()
    }

    func didTapNew() {
        guard let currentItem = currentItem else {
            return
        }

        do {
            let account = try interactor.createAccount(defaultAccountType: currentItem.coin.type.defaultAccountType)
            currentItem.wallet = interactor.createWallet(coin: currentItem.coin, account: account)
            view?.showSuccess()
        } catch {
            view?.updateUI()
            view?.show(error: error)
        }
    }

    func didTapRestore() {
        guard let currentItem = currentItem else {
            return
        }

        router.showRestore(defaultAccountType: currentItem.coin.type.defaultAccountType, delegate: self)
    }

    func didCancelCreate() {
        view?.updateUI()
    }

}

extension ManageWalletsPresenter: IManageWalletsInteractorDelegate {
}

extension ManageWalletsPresenter: IRestoreAccountTypeDelegate {

    func didRestore(accountType: AccountType, syncMode: SyncMode?) {
        guard let currentItem = currentItem else {
            return
        }

        let account = interactor.createRestoredAccount(accountType: accountType, defaultSyncMode: syncMode)
        currentItem.wallet = interactor.createWallet(coin: currentItem.coin, account: account)
    }

    func didCancelRestore() {
        view?.updateUI()
    }

}

class ManageWalletsPresenter {
    weak var view: IManageWalletsView?

    private let interactor: IManageWalletsInteractor
    private let router: IManageWalletsRouter

    private var wallets = [Coin: Wallet]()

    init(interactor: IManageWalletsInteractor, router: IManageWalletsRouter) {
        self.interactor = interactor
        self.router = router
    }

    private func account(coin: Coin) -> Account? {
        interactor.accounts.first { coin.type.canSupport(accountType: $0.type) }
    }

    private func viewItem(coin: Coin) -> CoinToggleViewItem {
        let enabled = wallets[coin] != nil
        let hasAccount = account(coin: coin) != nil
        let state: CoinToggleViewItemState = hasAccount ? .toggleVisible(enabled: enabled) : .toggleHidden
        return CoinToggleViewItem(coin: coin, state: state)
    }

    private func syncViewItems() {
        let featuredCoins = interactor.featuredCoins
        let coins = interactor.coins.filter { !featuredCoins.contains($0) }

        let featuredViewItems = featuredCoins.map { viewItem(coin: $0) }
        let viewItems = coins.map { viewItem(coin: $0) }

        view?.set(featuredViewItems: featuredViewItems, viewItems: viewItems)
    }

    private func createWallet(coin: Coin, account: Account, requestedCoinSettings: CoinSettings) {
        let coinSettings = interactor.coinSettingsToSave(coin: coin, accountOrigin: account.origin, requestedCoinSettings: requestedCoinSettings)

        let wallet = Wallet(coin: coin, account: account, coinSettings: coinSettings)

        interactor.save(wallet: wallet)
        wallets[coin] = wallet
    }

    //    private func enable(item: ManageWalletItem) {
//        if let wallet = interactor.wallet(coin: item.coin) {
//            item.wallet = wallet
//        } else if let predefinedAccountType = interactor.predefinedAccountType(coin: item.coin) {
//            currentItem = item
//            view?.showNoAccount(coin: item.coin, predefinedAccountType: predefinedAccountType)
//        }
//    }

}

extension ManageWalletsPresenter: IManageWalletsViewDelegate {

    func onLoad() {
        for wallet in interactor.wallets {
            wallets[wallet.coin] = wallet
        }

        syncViewItems()
    }

    func onEnable(viewItem: CoinToggleViewItem) {
        let coin = viewItem.coin

        guard let account = account(coin: coin) else {
            return
        }

        let coinSettingsToRequest = interactor.coinSettingsToRequest(coin: coin, accountOrigin: account.origin)

        if coinSettingsToRequest.isEmpty {
            createWallet(coin: coin, account: account, requestedCoinSettings: [:])
        } else {
            router.showCoinSettings(coin: coin, coinSettings: coinSettingsToRequest, delegate: self)
        }
    }

    func onDisable(viewItem: CoinToggleViewItem) {
        let coin = viewItem.coin

        guard let wallet = wallets[coin] else {
            return
        }

        interactor.delete(wallet: wallet)
        wallets.removeValue(forKey: coin)
    }

    func onSelect(viewItem: CoinToggleViewItem) {

    }

    func onTapCloseButton() {
        router.close()
    }

    func didTapNew() {
//        guard let currentItem = currentItem else {
//            return
//        }
//
//        do {
//            let account = try interactor.createAccount(defaultAccountType: currentItem.coin.type.defaultAccountType)
//            currentItem.wallet = interactor.createWallet(coin: currentItem.coin, account: account)
//            view?.showSuccess()
//        } catch {
//            view?.updateUI()
//            view?.show(error: error)
//        }
    }

    func didTapRestore() {
//        guard let currentItem = currentItem else {
//            return
//        }
//
//        router.showRestore(defaultAccountType: currentItem.coin.type.defaultAccountType, delegate: self)
    }

    func didCancelCreate() {
//        view?.updateUI()
    }

}

extension ManageWalletsPresenter: IManageWalletsInteractorDelegate {
}

extension ManageWalletsPresenter: ICoinSettingsDelegate {

    func onSelect(coinSettings: CoinSettings, coin: Coin) {
        guard let account = account(coin: coin) else {
            return
        }

        createWallet(coin: coin, account: account, requestedCoinSettings: coinSettings)
    }

    func onCancelSelectingCoinSettings() {
        syncViewItems()
    }

}

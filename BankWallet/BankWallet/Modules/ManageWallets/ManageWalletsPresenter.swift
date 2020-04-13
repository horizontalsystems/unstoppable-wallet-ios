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

    private func createWallet(coin: Coin) {
        guard let account = account(coin: coin) else {
            return
        }

        let wallet = Wallet(coin: coin, account: account)

        interactor.save(wallet: wallet)
        wallets[coin] = wallet
    }

    private func handleCreated(account: Account) {
        interactor.save(account: account)

        syncViewItems()
        view?.showSuccess()
    }

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

        if account.origin == .restored, let setting = interactor.derivationSetting(coinType: coin.type) {
            router.show(derivationSetting: setting, coin: coin, delegate: self)
        } else {
            createWallet(coin: coin)
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
        view?.showNoAccount(coin: viewItem.coin, predefinedAccountType: viewItem.coin.type.predefinedAccountType)
    }

    func onTapCloseButton() {
        router.close()
    }

    func onSelectNewAccount(predefinedAccountType: PredefinedAccountType) {
        do {
            let account = try interactor.createAccount(predefinedAccountType: predefinedAccountType)
            handleCreated(account: account)
        } catch {
            syncViewItems()
            view?.show(error: error)
        }
    }

    func onSelectRestoreAccount(predefinedAccountType: PredefinedAccountType) {
        router.showRestore(predefinedAccountType: predefinedAccountType)
    }

}

extension ManageWalletsPresenter: IManageWalletsInteractorDelegate {

    func didUpdateAccounts() {
        syncViewItems()
    }

}

extension ManageWalletsPresenter: IDerivationSettingDelegate {

    func onSelect(derivationSetting: DerivationSetting, coin: Coin) {
        interactor.save(derivationSetting: derivationSetting)
        createWallet(coin: coin)
    }

    func onCancelSelectDerivation() {
        syncViewItems()
    }

}

class ManageWalletsPresenter {
    weak var view: IManageWalletsView?

    private let presentationMode: ManageWalletsModule.PresentationMode
    private let interactor: IManageWalletsInteractor
    private let router: IManageWalletsRouter

    private var predefinedAccountType: PredefinedAccountType?
    private var accountType: AccountType?

    private var wallets = [Coin: Wallet]()

    init(presentationMode: ManageWalletsModule.PresentationMode, interactor: IManageWalletsInteractor, router: IManageWalletsRouter) {
        self.presentationMode = presentationMode
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

    private func createWallet(coin: Coin, account: Account) {
        let coinSettings = interactor.coinSettings(coinType: coin.type)

        let wallet = Wallet(coin: coin, account: account, coinSettings: coinSettings)

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
        view?.setCloseButton(visible: presentationMode == .presented)

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

        createWallet(coin: coin, account: account)
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
        self.predefinedAccountType = predefinedAccountType

        router.showRestore(predefinedAccountType: predefinedAccountType, delegate: self)
    }

}

extension ManageWalletsPresenter: IManageWalletsInteractorDelegate {
}

extension ManageWalletsPresenter: IBlockchainSettingsDelegate {

    func onConfirm() {
        guard let accountType = accountType else {
            return
        }

        let account = interactor.createRestoredAccount(accountType: accountType)
        handleCreated(account: account)

        router.closePresented()
    }

}

extension ManageWalletsPresenter: ICredentialsCheckDelegate {

    func didCheck(accountType: AccountType) {
        self.accountType = accountType
        guard let predefinedAccountType = predefinedAccountType else {
            return
        }

        if predefinedAccountType == .standard {
            router.showSettings(delegate: self)
        } else {
            let account = interactor.createRestoredAccount(accountType: accountType)
            handleCreated(account: account)

            router.closePresented()
        }
    }

}

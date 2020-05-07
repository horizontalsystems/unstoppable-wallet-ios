class CreateWalletPresenter {
    weak var view: ICreateWalletView?

    private let presentationMode: CreateWalletModule.PresentationMode
    private var predefinedAccountType: PredefinedAccountType?
    private let interactor: ICreateWalletInteractor
    private let router: ICreateWalletRouter

    private var accounts = [PredefinedAccountType: Account]()
    private var wallets = [Coin: Wallet]()

    init(presentationMode: CreateWalletModule.PresentationMode, predefinedAccountType: PredefinedAccountType?, interactor: ICreateWalletInteractor, router: ICreateWalletRouter) {
        self.presentationMode = presentationMode
        self.predefinedAccountType = predefinedAccountType
        self.interactor = interactor
        self.router = router
    }

    private func filteredCoins(coins: [Coin]) -> [Coin] {
        guard let predefinedAccountType = predefinedAccountType else {
            return coins
        }

        return coins.filter { $0.type.predefinedAccountType == predefinedAccountType }
    }

    private func viewItem(coin: Coin) -> CoinToggleViewItem? {
        guard coin.type.predefinedAccountType.createSupported else {
            return nil
        }

        return CoinToggleViewItem(
                coin: coin,
                state: .toggleVisible(enabled: wallets[coin] != nil)
        )
    }

    private func syncViewItems() {
        let featuredCoins = filteredCoins(coins: interactor.featuredCoins)
        let coins = filteredCoins(coins: interactor.coins).filter { !featuredCoins.contains($0) }

        let featuredViewItems = featuredCoins.compactMap { viewItem(coin: $0) }
        let viewItems = coins.compactMap { viewItem(coin: $0) }

        view?.set(featuredViewItems: featuredViewItems, viewItems: viewItems)
    }

    private func syncCreateButton() {
        view?.setCreateButton(enabled: !wallets.isEmpty)
    }

    private func resolveAccount(predefinedAccountType: PredefinedAccountType) throws -> Account {
        if let account = accounts[predefinedAccountType] {
            return account
        }

        let account = try interactor.account(predefinedAccountType: predefinedAccountType)
        accounts[predefinedAccountType] = account
        return account
    }

    private func createWallet(coin: Coin, account: Account) {
        wallets[coin] = Wallet(coin: coin, account: account)

        syncCreateButton()
    }

}

extension CreateWalletPresenter: ICreateWalletViewDelegate {

    func onLoad() {
        view?.setCancelButton(visible: presentationMode == .inApp)

        syncViewItems()
        syncCreateButton()
    }

    func onEnable(viewItem: CoinToggleViewItem) {
        let coin = viewItem.coin

        do {
            let account = try resolveAccount(predefinedAccountType: coin.type.predefinedAccountType)
            createWallet(coin: coin, account: account)
        } catch {
            view?.show(error: error)
            syncViewItems()
        }
    }

    func onDisable(viewItem: CoinToggleViewItem) {
        wallets.removeValue(forKey: viewItem.coin)
        syncCreateButton()
    }

    func onTapCreateButton() {
        guard !wallets.isEmpty else {
            return
        }

        let accounts = Array(Set(wallets.values.map { $0.account }))
        interactor.create(accounts: accounts)

        interactor.resetDerivationSettings()
        interactor.save(wallets: Array(wallets.values))

        switch presentationMode {
        case .initial:
            router.showMain()
        case .inApp:
            router.close()
        }
    }

    func onTapCancelButton() {
        router.close()
    }

}

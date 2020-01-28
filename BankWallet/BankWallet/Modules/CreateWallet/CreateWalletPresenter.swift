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

    private func viewItem(coin: Coin) -> CoinToggleViewItem {
        let state: CoinToggleViewItemState

        if coin.type.predefinedAccountType.createSupported {
            let enabled = wallets[coin] != nil
            state = .toggleVisible(enabled: enabled)
        } else {
            state = .toggleHidden
        }

        return CoinToggleViewItem(coin: coin, state: state)
    }

    private func syncViewItems() {
        let featuredCoins = filteredCoins(coins: interactor.featuredCoins)
        let coins = filteredCoins(coins: interactor.coins).filter { !featuredCoins.contains($0) }

        let featuredViewItems = featuredCoins.map { viewItem(coin: $0) }
        let viewItems = coins.map { viewItem(coin: $0) }

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

    private func createWallet(coin: Coin, account: Account, requestedCoinSettings: CoinSettings) {
        let coinSettings = interactor.coinSettings(coin: coin)

        wallets[coin] = Wallet(coin: coin, account: account, coinSettings: coinSettings)

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
            createWallet(coin: coin, account: account, requestedCoinSettings: [:])
        } catch {
            view?.show(error: error)
            syncViewItems()
        }
    }

    func onDisable(viewItem: CoinToggleViewItem) {
        wallets.removeValue(forKey: viewItem.coin)
        syncCreateButton()
    }

    func onSelect(viewItem: CoinToggleViewItem) {
        view?.showNotSupported(coin: viewItem.coin, predefinedAccountType: viewItem.coin.type.predefinedAccountType)
    }

    func onTapCreateButton() {
        guard !wallets.isEmpty else {
            return
        }

        let accounts = Array(Set(wallets.values.map { $0.account }))
        interactor.create(accounts: accounts)

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

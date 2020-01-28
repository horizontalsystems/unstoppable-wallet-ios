class RestoreCoinsPresenter {
    weak var view: IRestoreCoinsView?

    private let predefinedAccountType: PredefinedAccountType
    private let accountType: AccountType
    private let interactor: IRestoreCoinsInteractor
    private let router: IRestoreCoinsRouter

    private var enabledCoins = Set<Coin>()

    init(predefinedAccountType: PredefinedAccountType, accountType: AccountType, interactor: IRestoreCoinsInteractor, router: IRestoreCoinsRouter) {
        self.predefinedAccountType = predefinedAccountType
        self.accountType = accountType
        self.interactor = interactor
        self.router = router
    }

    private func filteredCoins(coins: [Coin]) -> [Coin] {
        coins.filter { $0.type.predefinedAccountType == predefinedAccountType }
    }

    private func viewItem(coin: Coin) -> CoinToggleViewItem {
        let enabled = enabledCoins.contains(coin)
        return CoinToggleViewItem(coin: coin, state: .toggleVisible(enabled: enabled))
    }

    private func syncViewItems() {
        let featuredCoins = filteredCoins(coins: interactor.featuredCoins)
        let coins = filteredCoins(coins: interactor.coins).filter { !featuredCoins.contains($0) }

        let featuredViewItems = featuredCoins.map { viewItem(coin: $0) }
        let viewItems = coins.map { viewItem(coin: $0) }

        view?.set(featuredViewItems: featuredViewItems, viewItems: viewItems)
    }

    private func syncProceedButton() {
        view?.setProceedButton(enabled: !enabledCoins.isEmpty)
    }

    private func enable(coin: Coin, requestedCoinSettings: CoinSettings) {
        enabledCoins.insert(coin)
        syncProceedButton()
    }

}

extension RestoreCoinsPresenter: IRestoreCoinsViewDelegate {

    func onLoad() {
        syncViewItems()
        syncProceedButton()
    }

    func onEnable(viewItem: CoinToggleViewItem) {
        enable(coin: viewItem.coin, requestedCoinSettings: [:])
    }

    func onDisable(viewItem: CoinToggleViewItem) {
        enabledCoins.remove(viewItem.coin)
        syncProceedButton()
    }

    func onTapRestore() {
        guard !enabledCoins.isEmpty else {
            return
        }

        let account = interactor.account(accountType: accountType)
        interactor.create(account: account)

        let wallets: [Wallet] = enabledCoins.map { coin in
            let coinSettings = interactor.coinSettings(coinType: coin.type)
            return Wallet(coin: coin, account: account, coinSettings: coinSettings)
        }

        interactor.save(wallets: wallets)

        router.notifyRestored()
    }

}

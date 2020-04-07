class RestoreCoinsPresenter {
    weak var view: IRestoreCoinsView?

    private let predefinedAccountType: PredefinedAccountType
    private let accountType: AccountType
    private let interactor: IRestoreCoinsInteractor
    private let router: IRestoreCoinsRouter

    private var enabledCoins = Set<Coin>()
    private var derivationSettings = [CoinType: DerivationSetting]()

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

    private func syncRestoreButton() {
        view?.setRestoreButton(enabled: !enabledCoins.isEmpty)
    }

    private func enable(coin: Coin) {
        enabledCoins.insert(coin)
        syncRestoreButton()

        if interactor.settings(coinType: coin.type) != nil {
//            router.showSettings(for: coin, settingsDelegate: self)
        }
    }

}

extension RestoreCoinsPresenter: IRestoreCoinsViewDelegate {

    func onLoad() {
        syncViewItems()
        syncRestoreButton()
    }

    func onEnable(viewItem: CoinToggleViewItem) {
        enable(coin: viewItem.coin)
    }

    func onDisable(viewItem: CoinToggleViewItem) {
        enabledCoins.remove(viewItem.coin)
        syncRestoreButton()
    }

    func onTapRestore() {
        guard !enabledCoins.isEmpty else {
            return
        }

        interactor.save(accountType: accountType, coins: Array(enabledCoins))
        router.finish()
    }

}

extension RestoreCoinsPresenter: IDerivationSettingsDelegate {

    func onConfirm(settings: [DerivationSetting]) {
        settings.forEach {
            derivationSettings[$0.coinType] = $0
        }
    }

}

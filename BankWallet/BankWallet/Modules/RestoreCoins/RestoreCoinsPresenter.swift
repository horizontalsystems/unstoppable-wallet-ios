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

    private func syncRestoreButton() {
        view?.setRestoreButton(enabled: !enabledCoins.isEmpty)
    }

    private func enable(coin: Coin) {
        enabledCoins.insert(coin)
        syncRestoreButton()
    }

}

extension RestoreCoinsPresenter: IRestoreCoinsViewDelegate {

    func onLoad() {
        syncViewItems()
        syncRestoreButton()
    }

    func onEnable(viewItem: CoinToggleViewItem) {
        let coin = viewItem.coin

        if let setting = interactor.derivationSetting(coinType: coin.type) {
            router.show(derivationSetting: setting, coin: coin, delegate: self)
        } else {
            enable(coin: coin)
        }
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

extension RestoreCoinsPresenter: IDerivationSettingDelegate {

    func onSelect(derivationSetting: DerivationSetting, coin: Coin) {
        interactor.save(derivationSetting: derivationSetting)
        enable(coin: coin)
    }

    func onCancelSelectDerivation() {
        syncViewItems()
    }

}

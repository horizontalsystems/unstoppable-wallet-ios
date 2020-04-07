protocol IRestoreCoinsView: class {
    func set(featuredViewItems: [CoinToggleViewItem], viewItems: [CoinToggleViewItem])
    func setRestoreButton(enabled: Bool)
}

protocol IRestoreCoinsViewDelegate {
    func onLoad()
    func onEnable(viewItem: CoinToggleViewItem)
    func onDisable(viewItem: CoinToggleViewItem)
    func onTapRestore()
}

protocol IRestoreCoinsInteractor {
    var coins: [Coin] { get }
    var featuredCoins: [Coin] { get }
    func settings(coinType: CoinType) -> DerivationSetting?
    func save(accountType: AccountType, coins: [Coin])
}

protocol IRestoreCoinsRouter {
    func finish()
}

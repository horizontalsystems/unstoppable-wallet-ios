protocol IRestoreCoinsView: class {
    func set(featuredViewItems: [CoinToggleViewItem], viewItems: [CoinToggleViewItem])
    func setProceedButton(enabled: Bool)
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

    func account(accountType: AccountType) -> Account

    func create(account: Account)
    func save(wallets: [Wallet])

    func coinSettings(coinType: CoinType) -> CoinSettings
}

protocol IRestoreCoinsRouter {
    func notifyRestored()
}

struct RestoreCoinsEnabledCoin {
    let coin: Coin
    let coinSettings: [CoinSetting: Any]
}

protocol IRestoreCoinsDelegate: AnyObject {
    func didRestore()
}


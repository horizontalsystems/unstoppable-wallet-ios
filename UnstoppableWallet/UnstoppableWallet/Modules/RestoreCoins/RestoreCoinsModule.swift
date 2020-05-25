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
    func derivationSetting(coinType: CoinType) -> DerivationSetting?
    func save(derivationSetting: DerivationSetting)
    func save(accountType: AccountType, coins: [Coin])
}

protocol IRestoreCoinsRouter {
    func showDerivationSetting(coin: Coin, currentDerivation: MnemonicDerivation, delegate: IDerivationSettingDelegate)
    func finish()
}

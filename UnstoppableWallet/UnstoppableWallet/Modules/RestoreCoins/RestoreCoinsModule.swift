protocol IRestoreCoinsView: class {
    func set(featuredViewItems: [CoinToggleViewModel.ViewItem], viewItems: [CoinToggleViewModel.ViewItem])
    func setRestoreButton(enabled: Bool)
}

protocol IRestoreCoinsViewDelegate {
    func onLoad()
    func onEnable(viewItem: CoinToggleViewModel.ViewItem)
    func onDisable(viewItem: CoinToggleViewModel.ViewItem)
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

protocol IRestoreCoinsView: class {
    func showNextButton()
    func showRestoreButton()
    func showDoneButton()
    func set(featuredViewItems: [CoinToggleViewItem], viewItems: [CoinToggleViewItem])
    func setProceedButton(enabled: Bool)
}

protocol IRestoreCoinsViewDelegate {
    func onLoad()
    func onEnable(viewItem: CoinToggleViewItem)
    func onDisable(viewItem: CoinToggleViewItem)
    func onProceed()
}

protocol IRestoreCoinsInteractor {
    var coins: [Coin] { get }
    var featuredCoins: [Coin] { get }
    func settings(coinType: CoinType) -> DerivationSetting?
}

protocol IRestoreCoinsRouter {
    func onSelect(coins: [Coin], derivationSettings: [DerivationSetting])
    func showSettings(for coin: Coin, settingsDelegate: IDerivationSettingsDelegate?)
}

protocol IRestoreCoinsDelegate: AnyObject {
    func onSelect(coins: [Coin], derivationSettings: [DerivationSetting])
}

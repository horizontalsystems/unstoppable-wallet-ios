protocol IDerivationSettingsView: class {
    func showNextButton()
    func showRestoreButton()
    func showDoneButton()

    func set(viewItems: [DerivationSettingSectionViewItem])
    func showChangeAlert(chainIndex: Int, settingIndex: Int, derivationText: String)
}

protocol IDerivationSettingsInteractor: class {
    var allCoins: [Coin] { get }
    func settings(coinType: CoinType) -> DerivationSetting?
    func walletsForUpdate(coinType: CoinType) -> [Wallet]

    func save(settings: [DerivationSetting])
    func update(wallets: [Wallet])
}

protocol IDerivationSettingsViewDelegate {
    func onLoad()
    func onConfirm()
    func onSelect(chainIndex: Int, settingIndex: Int)
    func proceedChange(chainIndex: Int, settingIndex: Int)
}

protocol IDerivationSettingsRouter {
    func open(url: String)
    func notifyConfirm(settings: [DerivationSetting])
    func close()
}

protocol IDerivationSettingsDelegate: class {
    func onConfirm(settings: [DerivationSetting])
}

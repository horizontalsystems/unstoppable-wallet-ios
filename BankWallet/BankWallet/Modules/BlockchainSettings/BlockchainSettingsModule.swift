protocol IBlockchainSettingsView: class {
    func showNextButton()
    func showRestoreButton()
    func showDoneButton()

    func set(viewItems: [DerivationSettingSectionViewItem])
    func showChangeAlert(chainIndex: Int, settingIndex: Int, derivationText: String)
}

protocol IBlockchainSettingsInteractor: class {
    var allCoins: [Coin] { get }
    func settings(coinType: CoinType) -> DerivationSetting?
    func walletsForUpdate(coinType: CoinType) -> [Wallet]

    func save(settings: [DerivationSetting])
    func update(wallets: [Wallet])
}

protocol IBlockchainSettingsViewDelegate {
    func onLoad()
    func onConfirm()
    func onSelect(chainIndex: Int, settingIndex: Int)
    func proceedChange(chainIndex: Int, settingIndex: Int)
}

protocol IBlockchainSettingsRouter {
    func open(url: String)
    func notifyConfirm(settings: [DerivationSetting])
    func close()
}

protocol IDerivationSettingsDelegate: class {
    func onConfirm(settings: [DerivationSetting])
}

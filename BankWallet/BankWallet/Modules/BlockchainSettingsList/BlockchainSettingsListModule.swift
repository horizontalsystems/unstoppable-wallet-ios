protocol IBlockchainSettingsListView: class {
    func showNextButton()
    func showRestoreButton()
    func showDoneButton()
    func set(viewItems: [BlockchainSettingsListViewItem])
}

protocol IBlockchainSettingsListViewDelegate {
    func onLoad()
    func onConfirm()
    func onSelect(index: Int)
}

protocol IBlockchainSettingsListRouter {
    func notifyConfirm(settings: [BlockchainSetting])
    func showSettings(coin: Coin, settings: BlockchainSetting, delegate: IBlockchainSettingsUpdateDelegate)
}

protocol IBlockchainSettingsListInteractor {
    var blockchainSettings: [BlockchainSetting] { get }
    var settableCoins: [Coin] { get }
    func save(settings: [BlockchainSetting])
    func update(wallets: [Wallet])
}

protocol IBlockchainSettingsUpdateDelegate {
    func onSelect(settings: BlockchainSetting, wallets: [Wallet])
}

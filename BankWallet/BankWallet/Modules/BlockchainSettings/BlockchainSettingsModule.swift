protocol IBlockchainSettingsView: class {
    func set(blockchainName: String)

    func showChangeAlert(derivation: MnemonicDerivation)
    func showChangeAlert(syncMode: SyncMode)
    func set(settings: BlockchainSetting)
}

protocol IBlockchainSettingsInteractor: class {
    func settings(coinType: CoinType) -> BlockchainSetting?
    func walletsForUpdate(coinType: CoinType) -> [Wallet]
}

protocol IBlockchainSettingsViewDelegate {
    func onLoad()
    func onSelect(derivation: MnemonicDerivation)
    func onSelect(syncMode: SyncMode)
    func proceedChange(derivation: MnemonicDerivation)
    func proceedChange(syncMode: SyncMode)
}

protocol IBlockchainSettingsRouter {
    func open(url: String)
}

protocol IBlockchainSettingsDelegate: class {
    func onConfirm(settings: [BlockchainSetting])
}

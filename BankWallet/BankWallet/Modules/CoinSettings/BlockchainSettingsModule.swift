protocol IBlockchainSettingsView: class {
    func showNextButton()
    func showRestoreButton()

    func set(derivation: MnemonicDerivation)
    func set(syncMode: SyncMode)
}

protocol IBlockchainSettingsInteractor: class {
    var bitcoinDerivation: MnemonicDerivation { get set }
    var syncMode: SyncMode { get set }
}

protocol IBlockchainSettingsViewDelegate {
    func onLoad()
    func onSelect(derivation: MnemonicDerivation)
    func onSelect(syncMode: SyncMode)
    func onConfirm()
}

protocol IBlockchainSettingsRouter {
    func notifyConfirm()
    func open(url: String)
}

protocol IBlockchainSettingsDelegate: class {
    func onConfirm()
}

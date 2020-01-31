protocol IBlockchainSettingsView: class {
    func showNextButton()
    func showRestoreButton()

    func set(derivation: MnemonicDerivation)
    func set(syncMode: SyncMode)
    func showChangeAlert(derivation: MnemonicDerivation)
    func showChangeAlert(syncMode: SyncMode)
}

protocol IBlockchainSettingsInteractor: class {
    var bitcoinDerivation: MnemonicDerivation { get set }
    var syncMode: SyncMode { get set }
    var walletsForDerivationUpdate: [Wallet] { get }
    var walletsForSyncModeUpdate: [Wallet] { get }
    func update(derivation: MnemonicDerivation, in wallets: [Wallet])
    func update(syncMode: SyncMode, in wallets: [Wallet])
}

protocol IBlockchainSettingsViewDelegate {
    func onLoad()
    func onSelect(derivation: MnemonicDerivation)
    func onSelect(syncMode: SyncMode)
    func onConfirm()
    func proceedChange(derivation: MnemonicDerivation)
    func proceedChange(syncMode: SyncMode)
}

protocol IBlockchainSettingsRouter {
    func notifyConfirm()
    func open(url: String)
}

protocol IBlockchainSettingsDelegate: class {
    func onConfirm()
}

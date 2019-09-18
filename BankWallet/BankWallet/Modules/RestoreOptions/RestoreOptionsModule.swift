protocol IRestoreOptionsView: class {
    func set(syncMode: SyncMode)
    func set(derivation: MnemonicDerivation)
}

protocol IRestoreOptionsViewDelegate {
    func viewDidLoad()
    func didTapDoneButton()
    func onTapFastSync()
    func onTapSlowSync()
    func onTapBeforeUpdate()
    func onTapAfterUpdate()
}

protocol IRestoreOptionsRouter {
    func notifyDelegate(syncMode: SyncMode, derivation: MnemonicDerivation)
}

protocol IRestoreOptionsDelegate: class {
    func onSelectRestoreOptions(syncMode: SyncMode, derivation: MnemonicDerivation)
}

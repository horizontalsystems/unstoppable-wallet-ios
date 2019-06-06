protocol ISyncModeView: class {
    func showInvalidWordsError()
}

protocol ISyncModeViewDelegate: class {
    func onSelectFast()
    func onSelectSlow()
    func onDone()
}

protocol ISyncModeInteractor {
    func restore(with words: [String], syncMode: SyncMode)
    func reSync(syncMode: SyncMode)
}

protocol ISyncModeInteractorDelegate: class {
    func didRestore()
    func didFailToRestore(withError error: Error)
    func didConfirmAgreement()
}

protocol ISyncModeRouter {
    func showAgreement()
    func navigateToSetPin()
}

enum SyncModuleStartMode {
    case initial(words: [String])
    case settings
}

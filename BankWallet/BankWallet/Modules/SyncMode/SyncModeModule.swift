protocol ISyncModeView: class {
}

protocol ISyncModeViewDelegate {
    func didSelectSyncMode(isFast: Bool)
}

protocol ISyncModeInteractor {
}

protocol ISyncModeInteractorDelegate: class {
}

protocol ISyncModeRouter {
    func notifyDelegate(isFast: Bool)
}

protocol ISyncModeDelegate: class {
    func onSelectSyncMode(isFast: Bool)
}

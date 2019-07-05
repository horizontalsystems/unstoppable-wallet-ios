class SyncModePresenter {
    weak var view: ISyncModeView?

    private let interactor: ISyncModeInteractor
    private let router: ISyncModeRouter

    init(interactor: ISyncModeInteractor, router: ISyncModeRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension SyncModePresenter: ISyncModeViewDelegate {

    func didSelectSyncMode(isFast: Bool) {
        router.notifyDelegate(isFast: isFast)
    }

}

extension SyncModePresenter: ISyncModeInteractorDelegate {
}

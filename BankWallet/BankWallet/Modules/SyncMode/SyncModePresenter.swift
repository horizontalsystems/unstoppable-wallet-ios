class SyncModePresenter {
    weak var view: ISyncModeView?

    private let router: ISyncModeRouter

    init(router: ISyncModeRouter) {
        self.router = router
    }

}

extension SyncModePresenter: ISyncModeViewDelegate {

    func didSelectSyncMode(isFast: Bool) {
        router.notifyDelegate(isFast: isFast)
    }

}

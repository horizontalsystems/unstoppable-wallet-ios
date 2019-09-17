class RestoreOptionsPresenter {
    weak var view: IRestoreOptionsView?

    private let router: IRestoreOptionsRouter

    init(router: IRestoreOptionsRouter) {
        self.router = router
    }

}

extension RestoreOptionsPresenter: IRestoreOptionsViewDelegate {

    func didSelectRestoreOptions(isFast: Bool) {
        router.notifyDelegate(isFast: isFast)
    }

}

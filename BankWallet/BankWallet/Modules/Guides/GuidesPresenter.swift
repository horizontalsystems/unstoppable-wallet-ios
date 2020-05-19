class GuidesPresenter {
    weak var view: IGuidesView?

    private let router: IGuidesRouter
    private let interactor: IGuidesInteractor

    init(router: IGuidesRouter, interactor: IGuidesInteractor) {
        self.router = router
        self.interactor = interactor
    }

}

extension GuidesPresenter: IGuidesViewDelegate {

    func onLoad() {

    }

}

extension GuidesPresenter: IGuidesInteractorDelegate {
}

class UnlinkPresenter {
    private let router: IUnlinkRouter
    private let interactor: IUnlinkInteractor

    weak var view: IUnlinkView?

    init(router: IUnlinkRouter, interactor: IUnlinkInteractor) {
        self.router = router
        self.interactor = interactor
    }

}

extension UnlinkPresenter: IUnlinkViewDelegate {

    func didTapUnlink() {
        interactor.unlink()
    }

}

extension UnlinkPresenter: IUnlinkInteractorDelegate {

    func didUnlink() {
        // todo
    }

}

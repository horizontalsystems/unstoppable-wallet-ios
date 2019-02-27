class AgreementPresenter {
    private let router: IAgreementRouter
    private let interactor: IAgreementInteractor

    weak var view: IAgreementView?

    init(router: IAgreementRouter, interactor: IAgreementInteractor) {
        self.router = router
        self.interactor = interactor
    }

}

extension AgreementPresenter: IAgreementViewDelegate {

    func didTapConfirm() {
        interactor.setConfirmed()
        router.dismissWithSuccess()
    }

}

extension AgreementPresenter: IAgreementInteractorDelegate {
}

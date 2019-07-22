class NoPasscodePresenter {
    private let interactor: INoPasscodeInteractor
    private let router: INoPasscodeRouter

    weak var view: INoPasscodeView?

    init(interactor: INoPasscodeInteractor, router: INoPasscodeRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension NoPasscodePresenter: INoPasscodeViewDelegate {
}

extension NoPasscodePresenter: INoPasscodeInteractorDelegate {
}

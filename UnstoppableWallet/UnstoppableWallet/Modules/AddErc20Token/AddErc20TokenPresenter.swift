class AddErc20TokenPresenter {
    weak var view: IAddErc20TokenView?

    private let interactor: IAddErc20TokenInteractor
    private let router: IAddErc20TokenRouter

    init(interactor: IAddErc20TokenInteractor, router: IAddErc20TokenRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension AddErc20TokenPresenter: IAddErc20TokenViewDelegate {

    func onTapCancel() {
        router.close()
    }

}

extension AddErc20TokenPresenter: IAddErc20TokenInteractorDelegate {
}

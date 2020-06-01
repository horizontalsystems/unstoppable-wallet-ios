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

    func onTapPasteAddress() {
        view?.set(address: "abcdef2736623b87237i723bi76v32iu6i276v8236i7o")
    }

    func onTapDeleteAddress() {
        view?.set(address: nil)
    }

    func onTapCancel() {
        router.close()
    }

}

extension AddErc20TokenPresenter: IAddErc20TokenInteractorDelegate {
}

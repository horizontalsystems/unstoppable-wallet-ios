class MainPresenter {

    let interactor: IMainInteractor
    let router: IMainRouter
    weak var view: IMainView?

    init(interactor: IMainInteractor, router: IMainRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension MainPresenter: IMainViewDelegate {

    func viewDidLoad() {
        interactor.setMainShownOnce()
    }

}

extension MainPresenter: IMainInteractorDelegate {
}

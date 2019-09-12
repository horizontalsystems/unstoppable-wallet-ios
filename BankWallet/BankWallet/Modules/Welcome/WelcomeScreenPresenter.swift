class WelcomeScreenPresenter {
    private let interactor: IWelcomeScreenInteractor
    private let router: IWelcomeScreenRouter

    weak var view: IWelcomeScreenView?

    init(interactor: IWelcomeScreenInteractor, router: IWelcomeScreenRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension WelcomeScreenPresenter: IWelcomeScreenViewDelegate {

    func viewDidLoad() {
        view?.set(appVersion: interactor.appVersion)
    }

    func didTapCreate() {
        router.showCreateWallet()
    }

    func didTapRestore() {
        router.showRestore(delegate: self)
    }
}

extension WelcomeScreenPresenter: IRestoreDelegate {

    func didRestore(account: Account) {
        router.showMain()
    }

}

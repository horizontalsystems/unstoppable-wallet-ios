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
        interactor.createWallet()
    }

    func didTapRestore() {
        router.showRestore(delegate: self)
    }
}

extension WelcomeScreenPresenter: IWelcomeScreenInteractorDelegate {

    func didCreateWallet() {
        router.showMain()
    }

    func didFailToCreateWallet(withError error: Error) {
        print("Login Error: \(error)")
        // TODO: show error in GUI
    }

}

extension WelcomeScreenPresenter: IRestoreDelegate {

    func didRestore(account: Account) {
        router.showMain()
    }

}

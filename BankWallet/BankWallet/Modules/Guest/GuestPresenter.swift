class GuestPresenter {
    private let interactor: IGuestInteractor
    private let router: IGuestRouter

    weak var view: IGuestView?

    init(interactor: IGuestInteractor, router: IGuestRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension GuestPresenter: IGuestInteractorDelegate {

    func didCreateWallet() {
        router.navigateToBackupRoutingToMain()
    }

    func didFailToCreateWallet(withError error: Error) {
        print("Login Error: \(error)")
        // TODO: show error in GUI
    }

}

extension GuestPresenter: IGuestViewDelegate {

    func viewDidLoad() {
        view?.set(appVersion: interactor.appVersion)
    }

    func createWalletDidClick() {
        interactor.createWallet()
    }

    func restoreWalletDidClick() {
        router.navigateToRestore()
    }

}

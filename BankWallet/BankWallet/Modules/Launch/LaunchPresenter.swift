class LaunchPresenter {
    private let interactor: ILaunchInteractor
    private let router: ILaunchRouter

    init(interactor: ILaunchInteractor, router: ILaunchRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension LaunchPresenter: ILaunchPresenter {

    func launch() {
        interactor.showLaunchModule()
    }

}

extension LaunchPresenter: ILaunchInteractorDelegate {

    func showWelcomeModule() {
        router.showWelcomeModule()
    }

    func showSetPinModule() {
        router.showSetPinModule()
    }

    func showMainModule() {
        router.showMainModule()
    }

    func showUnlockModule() {
        router.showUnlockModule()
    }

}

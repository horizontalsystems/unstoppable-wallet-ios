protocol ILaunchInteractor {
    func showLaunchModule()
}

protocol ILaunchInteractorDelegate: class {
    func showWelcomeModule()
    func showSetPinModule()
    func showMainModule()
    func showUnlockModule()
}

protocol ILaunchRouter {
    func showWelcomeModule()
    func showSetPinModule()
    func showMainModule()
    func showUnlockModule()
}

protocol ILaunchPresenter {
    func launch()
}

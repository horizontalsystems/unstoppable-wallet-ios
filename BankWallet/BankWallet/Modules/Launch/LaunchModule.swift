protocol ILaunchInteractor {
    func showLaunchModule()
}

protocol ILaunchInteractorDelegate: class {
    func showSetPinModule()
    func showMainModule()
    func showUnlockModule()
}

protocol ILaunchRouter {
    func showSetPinModule()
    func showMainModule()
    func showUnlockModule()
}

protocol ILaunchPresenter {
    func launch()
}

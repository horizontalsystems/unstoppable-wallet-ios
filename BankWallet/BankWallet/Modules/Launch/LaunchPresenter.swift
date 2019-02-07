import Foundation

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

    func showUnlockModule() {
        router.showUnlockModule()
    }

    func showMainModule() {
        router.showMainModule()
    }

    func showGuestModule() {
        router.showGuestModule()
    }

    func showSetPinModule() {
        router.showSetPinModule()
    }

    func showBackupModule() {
        router.showBackupModule()
    }

}

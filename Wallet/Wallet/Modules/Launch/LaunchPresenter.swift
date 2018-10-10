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

    func launch(shouldLock: Bool) {
        interactor.showLaunchModule(shouldLock: shouldLock)
    }

}

extension LaunchPresenter: ILaunchInteractorDelegate {

    func showMainModule() {
        router.showMainModule()
    }

    func showGuestModule() {
        router.showGuestModule()
    }

}

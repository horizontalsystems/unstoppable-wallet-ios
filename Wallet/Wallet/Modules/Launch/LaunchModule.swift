import Foundation

protocol ILaunchInteractor {
    func showLaunchModule(shouldLock: Bool)
}

protocol ILaunchInteractorDelegate: class {
    func showMainModule()
    func showGuestModule()
}

protocol ILaunchRouter {
    func showMainModule()
    func showGuestModule()
}

protocol ILaunchPresenter {
    func launch(shouldLock: Bool)
}

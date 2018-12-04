import Foundation

protocol ILaunchInteractor {
    func showLaunchModule()
}

protocol ILaunchInteractorDelegate: class {
    func showMainModule()
    func showGuestModule()
    func showSetPinModule()
    func showBackupModule()
}

protocol ILaunchRouter {
    func showMainModule()
    func showGuestModule()
    func showSetPinModule()
    func showBackupModule()
}

protocol ILaunchPresenter {
    func launch()
}

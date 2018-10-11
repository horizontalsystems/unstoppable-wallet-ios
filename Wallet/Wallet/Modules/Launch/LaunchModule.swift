import Foundation

protocol ILaunchInteractor {
    func showLaunchModule()
}

protocol ILaunchInteractorDelegate: class {
    func showMainModule()
    func showGuestModule()
    func showSetPinModule()
}

protocol ILaunchRouter {
    func showMainModule()
    func showGuestModule()
    func showSetPinModule()
}

protocol ILaunchPresenter {
    func launch()
}

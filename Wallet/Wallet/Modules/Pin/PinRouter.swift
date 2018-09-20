import UIKit

public protocol UnlockDelegate: class {
    func onUnlock()
}

class PinRouter {
    weak var viewController: UIViewController?

    var unlockWindow: UIWindow?
    var unlockController: UIViewController?
    weak var unlockDelegate: UnlockDelegate?

    init(unlockDelegate: UnlockDelegate? = nil) {
        self.unlockDelegate = unlockDelegate
    }

}

extension PinRouter: IPinRouter {

    func onSet(pin: String) {
        viewController?.navigationController?.pushViewController(PinRouter.confirmPinModule(pin: pin), animated: true)
    }

    func onConfirm() {
        viewController?.navigationController?.popToRootViewController(animated: true)
    }

    func onUnlock() {
        UIView.animate(withDuration: 0.3, animations: {
            self.unlockController?.view.frame.origin.y = UIScreen.main.bounds.height
        }, completion: { _ in
            self.unlockController = nil
            self.unlockWindow = nil
            self.unlockDelegate?.onUnlock()
        })
    }

    func onUnlockEdit() {
        viewController?.navigationController?.pushViewController(PinRouter.editPinModule(), animated: true)
    }

}

extension PinRouter {

    static func setPinModule() -> UIViewController {
        let router = PinRouter()
        let interactor = SetPinInteractor()
        let presenter = SetPinPresenter(interactor: interactor, router: router)
        let viewController = PinViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

    static func confirmPinModule(pin: String) -> UIViewController {
        let router = PinRouter()
        let interactor = ConfirmPinInteractor(pin: pin)
        let presenter = ConfirmPinPresenter(interactor: interactor, router: router)
        let viewController = PinViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

    static func editPinModule() -> UIViewController {
        let router = PinRouter()
        let interactor = NewPinInteractor()
        let presenter = NewPinPresenter(interactor: interactor, router: router)
        let viewController = PinViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

    static func unlockEditPinModule() -> UIViewController {
        let router = PinRouter()
        let interactor = UnlockEditPinInteractor(unlockHelper: UnlockHelper.shared)
        let presenter = UnlockEditPinPresenter(interactor: interactor, router: router)
        let viewController = PinViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

    static func unlockPinModule(unlockDelegate: UnlockDelegate?) {
        let router = PinRouter(unlockDelegate: unlockDelegate)
        let interactor = UnlockPinInteractor(unlockHelper: UnlockHelper.shared)
        let presenter = UnlockPinPresenter(interactor: interactor, router: router)
        let viewController = PinViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        router.unlockController = viewController
        router.unlockWindow = UIWindow(frame: UIScreen.main.bounds)
        viewController.view.frame = UIScreen.main.bounds
        router.unlockWindow?.rootViewController = viewController
        router.unlockWindow?.makeKeyAndVisible()
    }

}

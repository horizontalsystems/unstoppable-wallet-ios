import UIKit

public protocol UnlockDelegate: class {
    func onUnlock()
}

public protocol SetDelegate: class {
    func onSet()
}

class PinRouter {
    weak var viewController: UIViewController?

    weak var coverWindow: UIWindow?

    weak var unlockDelegate: UnlockDelegate?
    weak var setDelegate: SetDelegate?

    init(unlockDelegate: UnlockDelegate? = nil, setDelegate: SetDelegate? = nil) {
        self.unlockDelegate = unlockDelegate
        self.setDelegate = setDelegate
    }

}

extension PinRouter: IPinRouter {

    func onSet(pin: String) {
        viewController?.navigationController?.pushViewController(PinRouter.confirmPinModule(setDelegate: setDelegate, pin: pin, coverWindow: coverWindow), animated: true)
    }

    func onConfirm() {
        UIView.animate(withDuration: PinTheme.dismissAnimationDuration, animations: {
            self.coverWindow?.frame.origin.y = UIScreen.main.bounds.height
        }, completion: { _ in
            self.coverWindow = nil
            self.setDelegate?.onSet()
        })
    }

    func onUnlock() {
        UIView.animate(withDuration: PinTheme.dismissAnimationDuration, animations: {
            self.coverWindow?.frame.origin.y = UIScreen.main.bounds.height
        }, completion: { _ in
            self.coverWindow = nil
            self.unlockDelegate?.onUnlock()
        })
    }

    func onUnlockEdit() {
        viewController?.navigationController?.pushViewController(PinRouter.editPinModule(setDelegate: setDelegate), animated: true)
    }

}

extension PinRouter {

    @discardableResult
    static func setPinModule(setDelegate: SetDelegate?, from controller: UIViewController? = nil) -> UIWindow? {
        let router = PinRouter(setDelegate: setDelegate)
        let interactor = SetPinInteractor()
        let presenter = SetPinPresenter(interactor: interactor, router: router)
        let viewController = PinViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        if let controller = controller {
            controller.navigationController?.pushViewController(viewController, animated: true)
            return nil
        } else {
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.navigationBar.barStyle = AppTheme.navigationBarStyle
            navigationController.navigationBar.tintColor = AppTheme.navigationBarTintColor
            navigationController.navigationBar.prefersLargeTitles = true
            let window = UIWindow(frame: UIScreen.main.bounds)
            router.coverWindow = window
            viewController.view.frame = UIScreen.main.bounds
            router.coverWindow?.rootViewController = navigationController
            router.coverWindow?.makeKeyAndVisible()
            return window
        }
    }

    static func confirmPinModule(setDelegate: SetDelegate?, pin: String, coverWindow: UIWindow? = nil) -> UIViewController {
        let router = PinRouter(setDelegate: setDelegate)
        let interactor = ConfirmPinInteractor(pin: pin)
        let presenter = ConfirmPinPresenter(interactor: interactor, router: router)
        let viewController = PinViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController
        router.coverWindow = coverWindow

        return viewController
    }

    static func editPinModule(setDelegate: SetDelegate?) -> UIViewController {
        let router = PinRouter(setDelegate: setDelegate)
        let interactor = NewPinInteractor()
        let presenter = NewPinPresenter(interactor: interactor, router: router)
        let viewController = PinViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

    static func unlockEditPinModule(setDelegate: SetDelegate?) -> UIViewController {
        let router = PinRouter(setDelegate: setDelegate)
        let interactor = UnlockEditPinInteractor(unlockHelper: UnlockHelper.shared)
        let presenter = UnlockEditPinPresenter(interactor: interactor, router: router)
        let viewController = PinViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

    static func unlockPinModule(unlockDelegate: UnlockDelegate?) -> UIWindow {
        let router = PinRouter(unlockDelegate: unlockDelegate)
        let interactor = UnlockPinInteractor(unlockHelper: UnlockHelper.shared)
        let presenter = UnlockPinPresenter(interactor: interactor, router: router)
        let viewController = PinViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        let window = UIWindow(frame: UIScreen.main.bounds)
        router.coverWindow = window
        viewController.view.frame = UIScreen.main.bounds
        router.coverWindow?.rootViewController = viewController
        router.coverWindow?.makeKeyAndVisible()
        return window
    }

}

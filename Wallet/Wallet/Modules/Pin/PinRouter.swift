import UIKit

public protocol UnlockDelegate: class {
    func onUnlock(_ view: PinDismissInterface?)
}

public protocol SetDelegate: class {
    func onSet(_ view: PinDismissInterface?)
}

public protocol PinDismissInterface: class {
    func dismiss()
}

class PinRouter {
    weak var viewController: (UIViewController & PinDismissInterface)?

    weak var unlockDelegate: UnlockDelegate?
    weak var setDelegate: SetDelegate?

    init(unlockDelegate: UnlockDelegate? = nil, setDelegate: SetDelegate? = nil) {
        self.unlockDelegate = unlockDelegate
        self.setDelegate = setDelegate
    }

}

extension PinRouter: IPinRouter {

    func onSet(pin: String) {
        viewController?.navigationController?.pushViewController(PinRouter.confirmPinModule(setDelegate: setDelegate, pin: pin, title: "confirm_pin_controller.title".localized, info: "confirm_pin_controller.info".localized), animated: true)
    }

    func onSetNew(pin: String) {
        viewController?.navigationController?.pushViewController(PinRouter.confirmPinModule(setDelegate: setDelegate, pin: pin, title: "confirm_pin_controller.title".localized, info: nil), animated: true)
    }

    func onConfirm() {
        setDelegate?.onSet(viewController)
    }

    func onUnlock() {
        unlockDelegate?.onUnlock(viewController)
    }

    func onUnlockEdit() {
        viewController?.navigationController?.pushViewController(PinRouter.editPinModule(setDelegate: setDelegate), animated: true)
    }

}

extension PinRouter {

    static func setPinModule(setDelegate: SetDelegate?, from controller: UIViewController? = nil) {
        let router = PinRouter(setDelegate: setDelegate)
        let interactor = SetPinInteractor()
        let presenter = SetPinPresenter(interactor: interactor, router: router)
        let viewController = PinViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        if let controller = controller {
            controller.navigationController?.pushViewController(viewController, animated: true)
        } else {
            WalletNavigationController.show(rootViewController: viewController, customWindow: true)
        }
    }

    static func confirmPinModule(setDelegate: SetDelegate?, pin: String, title: String?, info: String?) -> UIViewController {
        let router = PinRouter(setDelegate: setDelegate)
        let interactor = ConfirmPinInteractor(pin: pin)
        let presenter = ConfirmPinPresenter(interactor: interactor, router: router, title: title, info: info)
        let viewController = PinViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

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

    static func unlockPinModule(unlockDelegate: UnlockDelegate?) {
        let router = PinRouter(unlockDelegate: unlockDelegate)
        let interactor = UnlockPinInteractor(unlockHelper: UnlockHelper.shared)
        let presenter = UnlockPinPresenter(interactor: interactor, router: router)
        let viewController = PinViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        let navigationController = WalletNavigationController.show(rootViewController: viewController, customWindow: true)
        navigationController.navigationBar.set(hidden: true)
    }

}

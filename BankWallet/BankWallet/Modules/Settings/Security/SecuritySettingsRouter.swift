import UIKit

class SecuritySettingsRouter {
    weak var viewController: UIViewController?
}

extension SecuritySettingsRouter: ISecuritySettingsRouter {

    func showManageAccounts() {
        viewController?.navigationController?.pushViewController(ManageAccountsRouter.module(mode: .pushed), animated: true)
    }

    func showSetPin(delegate: ISetPinDelegate) {
        viewController?.present(SetPinRouter.module(delegate: delegate), animated: true)
    }

    func showEditPin() {
        viewController?.present(EditPinRouter.module(), animated: true)
    }

    func showUnlock(delegate: IUnlockDelegate) {
        viewController?.present(UnlockPinRouter.module(delegate: delegate, enableBiometry: false, cancelable: true), animated: true)
    }

}

extension SecuritySettingsRouter {

    static func module() -> UIViewController {
        let router = SecuritySettingsRouter()
        let interactor = SecuritySettingsInteractor(localStorage: App.shared.localStorage, accountManager: App.shared.accountManager, biometryManager: App.shared.biometryManager, pinManager: App.shared.pinManager)
        let presenter = SecuritySettingsPresenter(router: router, interactor: interactor)
        let view = SecuritySettingsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}

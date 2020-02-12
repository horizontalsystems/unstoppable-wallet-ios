import UIKit
import PinKit

class SecuritySettingsRouter {
    weak var viewController: UIViewController?
}

extension SecuritySettingsRouter: ISecuritySettingsRouter {

    func showManageAccounts() {
        viewController?.navigationController?.pushViewController(ManageAccountsRouter.module(mode: .pushed), animated: true)
    }

    func showSetPin(delegate: ISetPinDelegate) {
        viewController?.present(App.shared.pinKit.setPinModule(delegate: delegate), animated: true)
    }

    func showEditPin() {
        viewController?.present(App.shared.pinKit.editPinModule, animated: true)
    }

    func showUnlock(delegate: IUnlockDelegate) {
        viewController?.present(App.shared.pinKit.unlockPinModule(delegate: delegate, enableBiometry: false, presentationStyle: .simple, cancellable: true), animated: true)
    }

}

extension SecuritySettingsRouter {

    static func module() -> UIViewController {
        let router = SecuritySettingsRouter()
        let interactor = SecuritySettingsInteractor(backupManager: App.shared.backupManager, pinKit: App.shared.pinKit)
        let presenter = SecuritySettingsPresenter(router: router, interactor: interactor)
        let view = SecuritySettingsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}

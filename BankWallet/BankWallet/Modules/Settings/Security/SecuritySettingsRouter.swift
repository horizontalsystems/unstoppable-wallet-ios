import UIKit

class SecuritySettingsRouter {
    weak var viewController: UIViewController?
    weak var unlockDelegate: IUnlockDelegate?
}

extension SecuritySettingsRouter: ISecuritySettingsRouter {

    func showManageAccounts() {
        viewController?.navigationController?.pushViewController(ManageAccountsRouter.module(mode: .pushed), animated: true)
    }

    func showSetPin() {
        viewController?.present(SetPinRouter.module(), animated: true)
    }

    func showEditPin() {
        viewController?.present(EditPinRouter.module(), animated: true)
    }

    func showUnlock() {
        viewController?.present(UnlockPinRouter.module(unlockDelegate: unlockDelegate, enableBiometry: false, cancelable: true), animated: true)
    }

}

extension SecuritySettingsRouter {

    static func module() -> UIViewController {
        let router = SecuritySettingsRouter()
        let interactor = SecuritySettingsInteractor(localStorage: App.shared.localStorage, accountManager: App.shared.accountManager, systemInfoManager: App.shared.systemInfoManager, pinManager: App.shared.pinManager)
        let presenter = SecuritySettingsPresenter(router: router, interactor: interactor, state: SecuritySettingsState())
        let view = SecuritySettingsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view
        router.unlockDelegate = interactor

        return view
    }

}

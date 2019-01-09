import UIKit

class SecuritySettingsRouter {
    weak var viewController: UIViewController?
}

extension SecuritySettingsRouter: ISecuritySettingsRouter {

    func showEditPin() {
        EditPinRouter.module(from: viewController)
    }

    func showSecretKey() {
        viewController?.present(BackupRouter.module(dismissMode: .dismissSelf), animated: true)
    }

    func showGuestModule() {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }

        let viewController = GuestRouter.module()

        UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
            window.rootViewController = viewController
        })
    }

}

extension SecuritySettingsRouter {

    static func module() -> UIViewController {
        let router = SecuritySettingsRouter()
        let interactor = SecuritySettingsInteractor(localStorage: App.shared.localStorage, authManager: App.shared.authManager, wordsManager: App.shared.wordsManager, systemInfoManager: App.shared.systemInfoManager)
        let presenter = SecuritySettingsPresenter(router: router, interactor: interactor)
        let view = SecuritySettingsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}

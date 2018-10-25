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

}

extension SecuritySettingsRouter {

    static func module() -> UIViewController {
        let router = SecuritySettingsRouter()
        let interactor = SecuritySettingsInteractor(localStorage: App.shared.localStorage, wordsManager: App.shared.wordsManager, systemInfoManager: App.shared.systemInfoManager)
        let presenter = SecuritySettingsPresenter(router: router, interactor: interactor)
        let view = SecuritySettingsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}

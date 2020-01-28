import UIKit
import ThemeKit

class WelcomeScreenRouter {
    weak var viewController: UIViewController?
}

extension WelcomeScreenRouter: IWelcomeScreenRouter {

    func showCreateWallet() {
        viewController?.navigationController?.pushViewController(CreateWalletRouter.module(presentationMode: .initial), animated: true)
    }

    func showRestoreWallet() {
        viewController?.navigationController?.pushViewController(RestoreRouter.module(), animated: true)
    }

}

extension WelcomeScreenRouter {

    static func module() -> UIViewController {
        let router = WelcomeScreenRouter()
        let interactor = WelcomeScreenInteractor(systemInfoManager: App.shared.systemInfoManager)
        let presenter = WelcomeScreenPresenter(interactor: interactor, router: router)
        let viewController = WelcomeScreenViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return ThemeNavigationController(rootViewController: viewController)
    }

}

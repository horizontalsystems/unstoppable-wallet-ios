import UIKit
import ThemeKit

class WelcomeScreenRouter {
    weak var viewController: UIViewController?
}

extension WelcomeScreenRouter: IWelcomeScreenRouter {

    func showCreateWallet() {
        viewController?.navigationController?.pushViewController(CreateWalletModule.instance(presentationMode: .initial), animated: true)
    }

    func showRestoreWallet() {
        RestoreModule.start(mode: .push(navigationController: viewController?.navigationController)) {
            UIApplication.shared.keyWindow?.set(newRootController: MainModule.instance(selectedTab: .balance))
        }
    }

    func showPrivacySettings() {
        viewController?.navigationController?.pushViewController(PrivacyRouter.module(), animated: true)
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

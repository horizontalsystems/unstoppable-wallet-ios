import UIKit
import ThemeKit

class WelcomeScreenRouter {
    weak var viewController: UIViewController?

    private func reloadAppInterface() {
        UIApplication.shared.keyWindow?.set(newRootController: MainModule.instance(selectedTab: .balance))
    }

}

extension WelcomeScreenRouter: IWelcomeScreenRouter {

    func showCreateWallet() {
        CreateWalletModule.start(mode: .push(navigationController: viewController?.navigationController)) { [weak self] in
            self?.reloadAppInterface()
        }
    }

    func showRestoreWallet() {
        RestoreModule.start(mode: .push(navigationController: viewController?.navigationController)) { [weak self] in
            self?.reloadAppInterface()
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

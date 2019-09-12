import UIKit

class WelcomeScreenRouter {
    weak var viewController: UIViewController?
}

extension WelcomeScreenRouter: IWelcomeScreenRouter {

    func showMain() {
        UIApplication.shared.keyWindow?.set(newRootController: MainRouter.module(selectedTab: .balance))
    }

    func showCreateWallet() {
        viewController?.navigationController?.pushViewController(CreateWalletRouter.module(), animated: true)
    }

    func showRestore(delegate: IRestoreDelegate) {
        viewController?.navigationController?.pushViewController(RestoreRouter.module(delegate: delegate), animated: true)
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

        return WalletNavigationController(rootViewController: viewController)
    }

}

import UIKit

class WelcomeScreenRouter {
    weak var viewController: UIViewController?
}

extension WelcomeScreenRouter: IWelcomeScreenRouter {

    func showMain() {
        UIApplication.shared.keyWindow?.set(newRootController: MainRouter.module(selectedTab: .balance))
    }

    func showRestore(delegate: IRestoreDelegate) {
        viewController?.present(RestoreRouter.module(delegate: delegate), animated: true)
    }

}

extension WelcomeScreenRouter {

    static func module() -> UIViewController {
        let router = WelcomeScreenRouter()
        let interactor = WelcomeScreenInteractor(accountCreator: App.shared.accountCreator, systemInfoManager: App.shared.systemInfoManager, predefinedAccountTypeManager: App.shared.predefinedAccountTypeManager)
        let presenter = WelcomeScreenPresenter(interactor: interactor, router: router)
        let viewController = WelcomeScreenViewController(delegate: presenter)

        presenter.view = viewController
        interactor.delegate = presenter
        router.viewController = viewController

        return viewController
    }

}

import UIKit

class CreateWalletRouter {
}

extension CreateWalletRouter: ICreateWalletRouter {

    func showMain() {
        UIApplication.shared.keyWindow?.set(newRootController: MainRouter.module(selectedTab: .balance))
    }

}

extension CreateWalletRouter {

    static func module() -> UIViewController {
        let router = CreateWalletRouter()
        let interactor = CreateWalletInteractor(appConfigProvider: App.shared.appConfigProvider, accountCreator: App.shared.accountCreator)
        let presenter = CreateWalletPresenter(interactor: interactor, router: router)
        let viewController = CreateWalletViewController(delegate: presenter)

        presenter.view = viewController

        return viewController
    }

}

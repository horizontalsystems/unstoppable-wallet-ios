import UIKit

class CreateWalletRouter {
    weak var viewController: UIViewController?
}

extension CreateWalletRouter: ICreateWalletRouter {
}

extension CreateWalletRouter {

    static func module() -> UIViewController {
        let router = CreateWalletRouter()
        let interactor = CreateWalletInteractor(appConfigProvider: App.shared.appConfigProvider)
        let presenter = CreateWalletPresenter(interactor: interactor, router: router)
        let viewController = CreateWalletViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}

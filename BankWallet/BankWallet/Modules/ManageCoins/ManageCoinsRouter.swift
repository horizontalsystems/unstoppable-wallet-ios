import UIKit

class ManageCoinsRouter {
    weak var viewController: UIViewController?
}

extension ManageCoinsRouter: IManageCoinsRouter {

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension ManageCoinsRouter {

    static func module(from presentingController: UIViewController?) {
        let router = ManageCoinsRouter()
        let interactor = ManageCoinsInteractor()
        let presenter = ManageCoinsPresenter(interactor: interactor, router: router, state: ManageCoinsPresenterState())
        let viewController = ManageCoinsViewController(delegate: presenter)

        interactor.delegate = presenter
        router.viewController = viewController

        presentingController?.present(WalletNavigationController(rootViewController: viewController), animated: true)
    }

}

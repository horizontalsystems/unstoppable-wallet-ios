import Foundation

class GuestRouter: GuestRouterProtocol {

    private weak var viewController: UIViewController?

    static var viewController: UIViewController {
        let router = GuestRouter()
        let interactor = GuestInteractor(router: router)
        let viewController = GuestViewController(interactor: interactor)

        router.viewController = viewController

        return viewController
    }

    func showCreateWallet() {
        viewController?.present(CreateWalletRouter.viewController, animated: true)
    }

    func showRestoreWallet() {
        viewController?.present(RestoreWalletRouter.viewController, animated: true)
    }
}

protocol GuestInteractorProtocol {
    func createNewWalletDidTap()
    func restoreWalletDidTap()
}

protocol GuestRouterProtocol {
    func showCreateWallet()
    func showRestoreWallet()
}

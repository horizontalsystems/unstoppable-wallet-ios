import Foundation

class GuestRouter {
    weak var viewController: UIViewController?
}

extension GuestRouter: GuestRouterProtocol {

    func showBackupWallet() {
        if let controller = BackupWalletRouter.viewController {
            viewController?.present(controller, animated: true)
        }
    }

    func showRestoreWallet() {
        viewController?.present(RestoreWalletRouter.viewController, animated: true)
    }

}

extension GuestRouter {

    static var viewController: UIViewController {
        let router = GuestRouter()
        let presenter = GuestPresenter(router: router)
        let viewController = GuestViewController(viewDelegate: presenter)

        router.viewController = viewController

        return viewController
    }

}

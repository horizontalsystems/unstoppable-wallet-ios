import Foundation

class GuestRouter {
    weak var viewController: UIViewController?
}

extension GuestRouter: GuestRouterProtocol {

    func showBackupWallet() {
        if let controller = BackupWalletModule.viewController {
            viewController?.present(controller, animated: true)
        }
    }

    func showRestoreWallet() {
//        viewController?.present(RestoreWalletModule.viewController, animated: true)
    }

}

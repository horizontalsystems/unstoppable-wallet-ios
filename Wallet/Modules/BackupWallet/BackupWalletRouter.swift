import Foundation

class BackupWalletRouter {
    weak var viewController: UIViewController?
}

extension BackupWalletRouter: BackupWalletRouterProtocol {

    func close() {
        viewController?.dismiss(animated: true)
    }

}

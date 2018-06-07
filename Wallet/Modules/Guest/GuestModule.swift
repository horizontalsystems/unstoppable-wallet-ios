import Foundation

class GuestModule {

    static var viewController: UIViewController {
        let router = GuestRouter()
        let presenter = GuestPresenter(router: router)
        let viewController = GuestViewController(viewDelegate: presenter)

        router.viewController = viewController

        return viewController
    }

}

protocol GuestViewDelegate {
    func createNewWalletDidTap()
    func restoreWalletDidTap()
}

protocol GuestRouterProtocol {
    func showBackupWallet()
    func showRestoreWallet()
}

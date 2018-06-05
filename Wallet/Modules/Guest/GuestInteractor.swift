import Foundation

class GuestInteractor: GuestInteractorProtocol {

    private let router: GuestRouterProtocol

    init(router: GuestRouterProtocol) {
        self.router = router
    }

    func createNewWalletDidTap() {
        router.showCreateWallet()
    }

    func restoreWalletDidTap() {
        router.showRestoreWallet()
    }

}

import Foundation

class GuestPresenter {

    private let router: GuestRouterProtocol

    init(router: GuestRouterProtocol) {
        self.router = router
    }

}

extension GuestPresenter: GuestViewDelegate {

    func createNewWalletDidTap() {
        router.showBackupWallet()
    }

    func restoreWalletDidTap() {
        router.showRestoreWallet()
    }

}

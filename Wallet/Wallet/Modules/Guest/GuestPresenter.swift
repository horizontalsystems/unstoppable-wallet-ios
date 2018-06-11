import Foundation

class GuestPresenter {

    private let delegate: GuestPresenterDelegate
    private let router: GuestRouterProtocol

    init(delegate: GuestPresenterDelegate, router: GuestRouterProtocol) {
        self.delegate = delegate
        self.router = router
    }

}

extension GuestPresenter: GuestPresenterProtocol {

    func didCreateWallet() {
        router.showBackupRoutingToMain()
    }

}

extension GuestPresenter: GuestViewDelegate {

    func createNewWalletDidTap() {
        delegate.createWallet()
    }

    func restoreWalletDidTap() {
        router.showRestoreWallet()
    }

}

import Foundation

protocol GuestViewDelegate {
    func createNewWalletDidTap()
    func restoreWalletDidTap()
}

protocol GuestViewProtocol: class {
}

protocol GuestPresenterDelegate {
    func createWallet()
}

protocol GuestPresenterProtocol: class {
    func didCreateWallet()
}

protocol GuestRouterProtocol {
    func showBackupRoutingToMain()
    func showRestoreWallet()
}

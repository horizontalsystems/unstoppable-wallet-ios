import Foundation

protocol GuestViewDelegate {
    func createNewWalletDidTap()
    func restoreWalletDidTap()
}

protocol GuestRouterProtocol {
    func showBackupWallet()
    func showRestoreWallet()
}

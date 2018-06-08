import Foundation

protocol GuestViewDelegate {
    func createNewWalletDidTap()
    func restoreWalletDidTap()
}

protocol GuestRouterProtocol {
    func showMain()
    func showRestoreWallet()
}

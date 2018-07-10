import Foundation

protocol IGuestViewDelegate {
    func createWalletDidClick()
    func restoreWalletDidClick()
}

protocol IGuestInteractor {
    func createWallet()
}

protocol IGuestInteractorDelegate: class {
    func didCreateWallet()
    func didFailToCreateWallet(withError error: Error)
}

protocol IGuestRouter {
    func navigateToBackupRoutingToMain()
    func navigateToRestore()
}

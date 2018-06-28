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
    func didFailToCreateWallet()
}

protocol IGuestRouter {
    func navigateToBackupRoutingToMain()
    func navigateToRestore()
}

import Foundation

protocol IGuestViewDelegate {
    func willAppear()
    func willDisappear()
    func createWalletDidClick()
    func restoreWalletDidClick()
}

protocol IGuestInteractor {
    func willAppear()
    func willDisAppear()
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

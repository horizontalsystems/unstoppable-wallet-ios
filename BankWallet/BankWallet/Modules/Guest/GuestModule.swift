import Foundation

protocol IGuestView: class {
    func set(appVersion: String)
}

protocol IGuestViewDelegate {
    func viewDidLoad()
    func createWalletDidClick()
    func restoreWalletDidClick()
}

protocol IGuestInteractor {
    var appVersion: String { get }
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

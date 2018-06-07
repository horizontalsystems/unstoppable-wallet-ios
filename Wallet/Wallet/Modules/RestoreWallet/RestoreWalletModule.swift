import Foundation

protocol RestoreWalletViewDelegate {
    func cancelDidTap()
}

protocol RestoreWalletViewProtocol: class {
}

protocol RestoreWalletPresenterDelegate {
}

protocol RestoreWalletPresenterProtocol: class {
}

protocol RestoreWalletRouterProtocol {
    func close()
}

import Foundation

protocol RestoreViewDelegate {
    func restoreDidTap(withWords words: [String])
    func cancelDidTap()
}

protocol RestoreViewProtocol: class {
    func showWordsValidationFailure()
}

protocol RestorePresenterDelegate {
    func restoreWallet(withWords words: [String])
}

protocol RestorePresenterProtocol: class {
    func didFailToRestore()
    func didRestoreWallet()
}

protocol RestoreRouterProtocol {
    func navigateToMain()
    func close()
}

import Foundation

protocol IRestoreView: class {
    func showInvalidWordsError()
    func showConfirmAlert()
}

protocol IRestoreViewDelegate {
    func restoreDidClick(withWords words: [String])
    func cancelDidClick()
    func didConfirm(words: [String])
}

protocol IRestoreInteractor {
    func restore(withWords words: [String])
    func validate(words: [String])
}

protocol IRestoreInteractorDelegate: class {
    func didRestore()
    func didFailToRestore(withError error: Error)
    func didValidate()
    func didFailToValidate(withError error: Error)
}

protocol IRestoreRouter {
    func navigateToSetPin()
    func close()
}

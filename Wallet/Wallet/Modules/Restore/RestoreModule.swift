import Foundation

protocol IRestoreView: class {
    func showInvalidWordsError()
}

protocol IRestoreViewDelegate {
    func restoreDidClick(withWords words: [String])
    func cancelDidClick()
}

protocol IRestoreInteractor {
    func restore(withWords words: [String])
}

protocol IRestoreInteractorDelegate: class {
    func didRestore()
    func didFailToRestore(withError error: Error)
}

protocol IRestoreRouter {
    func navigateToMain()
    func close()
}

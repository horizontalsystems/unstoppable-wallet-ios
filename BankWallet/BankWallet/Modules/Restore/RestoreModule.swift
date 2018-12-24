protocol IRestoreView: class {
    func set(defaultWords: [String])
    func showInvalidWordsError()
    func showConfirmAlert()
}

protocol IRestoreViewDelegate {
    func viewDidLoad()
    func restoreDidClick(withWords words: [String])
    func cancelDidClick()
    func didConfirm(words: [String])
}

protocol IRestoreInteractor {
    var defaultWords: [String] { get }
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

protocol IRestoreView: class {
    func set(defaultWords: [String])
    func showInvalidWordsError()
}

protocol IRestoreViewDelegate {
    func viewDidLoad()
    func restoreDidClick(withWords words: [String])
    func cancelDidClick()
}

protocol IRestoreInteractor {
    var defaultWords: [String] { get }
    func restore(withWords words: [String])
    func validate(words: [String])
}

protocol IRestoreInteractorDelegate: class {
    func didRestore()
    func didFailToRestore(withError error: Error)
    func didValidate(words: [String])
    func didFailToValidate(withError error: Error)
    func didConfirmAgreement()
}

protocol IRestoreRouter {
    func showAgreement()
    func navigateToSetPin()
    func close()
}

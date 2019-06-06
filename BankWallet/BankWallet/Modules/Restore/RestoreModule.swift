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
    func validate(words: [String])
}

protocol IRestoreInteractorDelegate: class {
    func didValidate(words: [String])
    func didFailToValidate(withError error: Error)
}

protocol IRestoreRouter {
    func openSyncMode(with words: [String])
    func close()
}

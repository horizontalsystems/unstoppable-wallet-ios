protocol IRestoreWordsView: class {
    func show(defaultWords: [String])
    func show(error: Error)
}

protocol IRestoreWordsViewDelegate {
    func viewDidLoad()
    func didTapRestore(words: [String])
}

protocol IRestoreWordsInteractor {
    var defaultWords: [String] { get }
    func validate(words: [String]) throws
}

protocol IRestoreWordsInteractorDelegate: class {
    func didSelectSyncMode(isFast: Bool)
}

protocol IRestoreWordsRouter {
    func showSyncMode()
    func notifyRestored(accountType: AccountType, syncMode: SyncMode)
}

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
}

protocol IRestoreWordsRouter {
    func showSyncMode(delegate: ISyncModeDelegate)
    func notifyRestored(accountType: AccountType, syncMode: SyncMode)
}

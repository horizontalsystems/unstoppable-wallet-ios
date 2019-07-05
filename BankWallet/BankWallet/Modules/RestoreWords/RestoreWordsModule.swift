protocol IRestoreWordsView: class {
    func show(defaultWords: [String])
    func show(error: Error)
}

protocol IRestoreWordsViewDelegate {
    func viewDidLoad()
    func didTapRestore(words: [String])
}

protocol IRestoreWordsRouter {
    func showSyncMode(delegate: ISyncModeDelegate)
    func notifyRestored(accountType: AccountType, syncMode: SyncMode)
}

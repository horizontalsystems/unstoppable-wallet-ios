protocol IRestoreWordsView: class {
    func showCancelButton()
    func show(defaultWords: [String])
    func show(error: Error)
}

protocol IRestoreWordsViewDelegate {
    var wordsCount: Int { get }
    func viewDidLoad()
    func didTapRestore(words: [String])
    func didTapCancel()
}

protocol IRestoreWordsRouter {
    func showSyncMode(delegate: ISyncModeDelegate)
    func notifyRestored(accountType: AccountType, syncMode: SyncMode)
    func dismissAndNotify(accountType: AccountType, syncMode: SyncMode)
    func dismiss()
}

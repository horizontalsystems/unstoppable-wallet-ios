protocol IRestoreWordsView: class {
    func showCancelButton()
    func showRestoreButton()

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
    func notifyRestored(accountType: AccountType)
    func dismissAndNotify(accountType: AccountType)
    func dismiss()
}

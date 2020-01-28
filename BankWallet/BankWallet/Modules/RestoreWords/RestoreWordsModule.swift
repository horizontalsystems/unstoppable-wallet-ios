protocol IRestoreWordsView: class {
    func showCancelButton()
    func showNextButton()
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
    func notifyChecked(accountType: AccountType)
    func dismiss()
}

protocol ICredentialsCheckDelegate: AnyObject {
    func didCheck(accountType: AccountType)
}

protocol IBackupWordsView: class {
    func show(words: [String])
}

protocol IBackupWordsViewDelegate {
    var words: [String] { get }
    func showConfirmationDidTap()
}

protocol IBackupWordsPresenter {
}

protocol IBackupWordsRouter {
    func showConfirmation(delegate: IBackupConfirmationDelegate, words: [String])
    func notifyBackedUp()
}

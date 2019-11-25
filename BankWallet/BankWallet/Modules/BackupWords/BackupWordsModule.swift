protocol IBackupWordsView: class {
    func show(words: [String])
}

protocol IBackupWordsViewDelegate {
    var isBackedUp: Bool { get }
    var words: [String] { get }
    func didTapProceed()
}

protocol IBackupWordsPresenter {
}

protocol IBackupWordsRouter {
    func showConfirmation(delegate: IBackupConfirmationDelegate, words: [String], predefinedAccountType: PredefinedAccountType)
    func notifyBackedUp()
    func notifyClosed()
}

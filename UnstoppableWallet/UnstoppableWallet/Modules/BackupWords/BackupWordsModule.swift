protocol IBackupWordsView: class {
    func show(words: [String])
}

protocol IBackupWordsViewDelegate {
    var isBackedUp: Bool { get }
    var words: [String] { get }
    var additionalItems: [BackupAdditionalItem] { get }
    func didTapProceed()
}

protocol IBackupWordsPresenter {
}

protocol IBackupWordsRouter {
    func showConfirmation(delegate: IBackupConfirmationDelegate, words: [String], predefinedAccountType: PredefinedAccountType)
    func notifyBackedUp()
    func notifyClosed()
}

struct BackupAdditionalItem {
    let copyable: Bool
    let title: String
    let value: String

    init(title: String, value: String, copyable: Bool = true) {
        self.title = title
        self.value = value
        self.copyable = copyable
    }

}
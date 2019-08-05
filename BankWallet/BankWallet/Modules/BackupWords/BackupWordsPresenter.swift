class BackupWordsPresenter: IBackupWordsPresenter {

    private let router: IBackupWordsRouter

    private(set) var words: [String]
    let isBackedUp: Bool

    init(router: IBackupWordsRouter, words: [String], isBackedUp: Bool) {
        self.router = router
        self.words = words
        self.isBackedUp = isBackedUp
    }

}

extension BackupWordsPresenter: IBackupWordsViewDelegate {

    func didTapProceed() {
        if isBackedUp {
            router.notifyClosed()
        } else {
            router.showConfirmation(delegate: self, words: words)
        }
    }

}

extension BackupWordsPresenter: IBackupConfirmationDelegate {

    func didValidate() {
        router.notifyBackedUp()
    }

}

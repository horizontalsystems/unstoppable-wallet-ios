class BackupWordsPresenter: IBackupWordsPresenter {

    private let router: IBackupWordsRouter

    private(set) var words: [String]

    init(router: IBackupWordsRouter, words: [String]) {
        self.router = router
        self.words = words
    }

}

extension BackupWordsPresenter: IBackupWordsViewDelegate {

    func showConfirmationDidTap() {
        router.showConfirmation(delegate: self, words: words)
    }

}

extension BackupWordsPresenter: IBackupConfirmationDelegate {

    func didValidate() {
        router.notifyBackedUp()
    }

}

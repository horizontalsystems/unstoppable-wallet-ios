class BackupWordsPresenter: IBackupWordsPresenter {

    private let router: IBackupWordsRouter

    private(set) var words: [String]
    let isBackedUp: Bool
    let predefinedAccountType: IPredefinedAccountType

    init(router: IBackupWordsRouter, predefinedAccountType: IPredefinedAccountType, words: [String], isBackedUp: Bool) {
        self.router = router
        self.predefinedAccountType = predefinedAccountType
        self.words = words
        self.isBackedUp = isBackedUp
    }

}

extension BackupWordsPresenter: IBackupWordsViewDelegate {

    func didTapProceed() {
        if isBackedUp {
            router.notifyClosed()
        } else {
            router.showConfirmation(delegate: self, words: words, predefinedAccountType: predefinedAccountType)
        }
    }

}

extension BackupWordsPresenter: IBackupConfirmationDelegate {

    func didValidate() {
        router.notifyBackedUp()
    }

}

class BackupWordsPresenter: IBackupWordsPresenter {

    private let router: IBackupWordsRouter

    private(set) var words: [String]
    private(set) var additionalItems: [BackupAdditionalItem]
    let isBackedUp: Bool
    let predefinedAccountType: PredefinedAccountType

    init(router: IBackupWordsRouter, predefinedAccountType: PredefinedAccountType, words: [String], additionalItems: [BackupAdditionalItem] = [], isBackedUp: Bool) {
        self.router = router
        self.predefinedAccountType = predefinedAccountType
        self.words = words
        self.additionalItems = additionalItems
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

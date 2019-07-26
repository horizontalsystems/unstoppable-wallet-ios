class BackupEosPresenter: IBackupEosPresenter {
    private let router: IBackupEosRouter

    let account: String
    let activePrivateKey: String

    init(router: IBackupEosRouter, account: String, activePrivateKey: String) {
        self.router = router
        self.account = account
        self.activePrivateKey = activePrivateKey
    }

}

extension BackupEosPresenter: IBackupEosViewDelegate {

    func didTapClose() {
        router.notifyClosed()
    }

}

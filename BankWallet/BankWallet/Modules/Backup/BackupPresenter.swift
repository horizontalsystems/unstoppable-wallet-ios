class BackupPresenter: IBackupPresenter {
    weak var view: IBackupWordsView? = nil

    private let router: IBackupRouter
    private let interactor: IBackupInteractor
    private let account: Account

    init(interactor: IBackupInteractor, router: IBackupRouter, account: Account) {
        self.interactor = interactor
        self.router = router
        self.account = account
    }

}

extension BackupPresenter: IBackupViewDelegate {

    func cancelDidClick() {
        router.close()
    }

    func backupDidTap() {
        if interactor.isPinSet {
            router.showUnlock()
        } else {
            router.showBackup(accountType: account.type, delegate: self)
        }
    }

}

extension BackupPresenter: IUnlockDelegate {

    func onUnlock() {
        router.showBackup(accountType: account.type, delegate: self)
    }

    func onCancelUnlock() {
    }

}

extension BackupPresenter: IBackupDelegate {

    func didBackUp() {
        interactor.setBackedUp(accountId: account.id)
        router.close()
    }

}

class BackupPresenter: IBackupPresenter {
    weak var view: IBackupWordsView? = nil

    private let router: IBackupRouter
    private let interactor: IBackupInteractor
    private let account: Account
    private let predefinedAccountType: IPredefinedAccountType

    init(interactor: IBackupInteractor, router: IBackupRouter, account: Account, predefinedAccountType: IPredefinedAccountType) {
        self.interactor = interactor
        self.router = router
        self.account = account
        self.predefinedAccountType = predefinedAccountType
    }

}

extension BackupPresenter: IBackupViewDelegate {

    var isBackedUp: Bool {
        return account.backedUp
    }

    var coinCodes: String {
        return predefinedAccountType.coinCodes
    }

    func cancelDidClick() {
        router.close()
    }

    func proceedDidTap() {
        if interactor.isPinSet {
            router.showUnlock()
        } else {
            router.showBackup(account: account, delegate: self)
        }
    }

}

extension BackupPresenter: IUnlockDelegate {

    func onUnlock() {
        router.showBackup(account: account, delegate: self)
    }

    func onCancelUnlock() {
    }

}

extension BackupPresenter: IBackupDelegate {

    func didBackUp() {
        interactor.setBackedUp(accountId: account.id)
        router.close()
    }

    func didClose() {
        router.close()
    }

}

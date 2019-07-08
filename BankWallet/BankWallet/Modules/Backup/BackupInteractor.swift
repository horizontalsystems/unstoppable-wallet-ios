class BackupInteractor: IBackupInteractor {
    private let accountManager: IAccountManager

    init(accountManager: IAccountManager) {
        self.accountManager = accountManager
    }

    func setBackedUp(accountId: String) {
        accountManager.setAccountBackedUp(id: accountId)
    }

}

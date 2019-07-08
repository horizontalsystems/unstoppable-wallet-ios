class BackupInteractor {
    private let accountId: String
    private let accountManager: IAccountManager

    init(accountId: String, accountManager: IAccountManager) {
        self.accountId = accountId
        self.accountManager = accountManager
    }

}

extension BackupInteractor: IBackupInteractor {

    func setBackedUp() {
        accountManager.setAccountBackedUp(id: accountId)
    }

}

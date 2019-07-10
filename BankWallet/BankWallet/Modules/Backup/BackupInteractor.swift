class BackupInteractor {
    private let accountManager: IAccountManager
    private let pinManager: IPinManager

    init(accountManager: IAccountManager, pinManager: IPinManager) {
        self.accountManager = accountManager
        self.pinManager = pinManager
    }

}

extension BackupInteractor: IBackupInteractor {

    var isPinSet: Bool {
        return pinManager.isPinSet
    }

    func setBackedUp(accountId: String) {
        accountManager.setAccountBackedUp(id: accountId)
    }

}

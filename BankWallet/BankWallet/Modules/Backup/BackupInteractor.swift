class BackupInteractor {
    private let backupManager: IBackupManager
    private let pinManager: IPinManager

    init(backupManager: IBackupManager, pinManager: IPinManager) {
        self.backupManager = backupManager
        self.pinManager = pinManager
    }

}

extension BackupInteractor: IBackupInteractor {

    var isPinSet: Bool {
        return pinManager.isPinSet
    }

    func setBackedUp(accountId: String) {
        backupManager.setAccountBackedUp(id: accountId)
    }

}

import PinKit

class BackupInteractor {
    private let backupManager: IBackupManager
    private let pinKit: IPinKit

    init(backupManager: IBackupManager, pinKit: IPinKit) {
        self.backupManager = backupManager
        self.pinKit = pinKit
    }

}

extension BackupInteractor: IBackupInteractor {

    var isPinSet: Bool {
        pinKit.isPinSet
    }

    func setBackedUp(accountId: String) {
        backupManager.setAccountBackedUp(id: accountId)
    }

}

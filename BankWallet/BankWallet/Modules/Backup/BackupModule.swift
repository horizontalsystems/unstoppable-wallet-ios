protocol IBackupViewDelegate {
    func cancelDidClick()
    func backupDidTap()
}

protocol IBackupRouter {
    func showUnlock()
    func showBackup(accountType: AccountType, delegate: IBackupDelegate)
    func close()
}

protocol IBackupPresenter: IBackupViewDelegate {
}

protocol IBackupDelegate {
    func didBackUp()
}

protocol IBackupInteractor {
    var isPinSet: Bool { get }
    func setBackedUp(accountId: String)
}

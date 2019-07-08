protocol IBackupViewDelegate {
    func cancelDidClick()
    func backupDidTap()
}

protocol IBackupRouter {
    func showUnlock()
    func show(words: [String], delegate: IBackupDelegate)
    func showEOS(account: Account, delegate: IBackupDelegate)
    func close()
}

protocol IBackupPresenter: IBackupViewDelegate {
}

protocol IBackupDelegate {
    func didBackUp()
}

protocol IBackupInteractor {
    func setBackedUp()
}

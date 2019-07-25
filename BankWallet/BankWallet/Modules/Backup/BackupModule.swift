protocol IBackupViewDelegate {
    var isBackedUp: Bool { get }
    var coinCodes: String { get }
    func cancelDidClick()
    func proceedDidTap()
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

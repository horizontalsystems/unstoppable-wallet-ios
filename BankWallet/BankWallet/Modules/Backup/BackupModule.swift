protocol IBackupViewDelegate {
    var isBackedUp: Bool { get }
    var coinCodes: String { get }
    func cancelDidClick()
    func proceedDidTap()
}

protocol IBackupRouter {
    func showUnlock()
    func showBackup(account: Account, predefinedAccountType: IPredefinedAccountType, delegate: IBackupDelegate)
    func close()
}

protocol IBackupPresenter: IBackupViewDelegate {
}

protocol IBackupDelegate {
    func didBackUp()
    func didClose()
}

protocol IBackupInteractor {
    var isPinSet: Bool { get }
    func setBackedUp(accountId: String)
}

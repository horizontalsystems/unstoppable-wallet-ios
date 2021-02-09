protocol IManageAccountsView: class {
    func set(viewItems: [ManageAccountViewItem])
    func show(error: Error)
    func showSuccess()
}

protocol IManageAccountsViewDelegate {
    func viewDidLoad()

    func didTapUnlink(index: Int)
    func didTapBackup(index: Int)
    func didTapCreate(index: Int)
    func didTapRestore(index: Int)
    func didTapSettings(index: Int)
}

protocol IManageAccountsInteractor {
    var predefinedAccountTypes: [PredefinedAccountType] { get }
    var hasAddressFormatSettings: Bool { get }
    func account(predefinedAccountType: PredefinedAccountType) -> Account?
}

protocol IManageAccountsInteractorDelegate: class {
    func didUpdateAccounts()
    func didUpdateWallets()
}

protocol IManageAccountsRouter {
    func showUnlink(account: Account, predefinedAccountType: PredefinedAccountType)
    func showBackup(account: Account, predefinedAccountType: PredefinedAccountType)
    func showBackupRequired(account: Account, predefinedAccountType: PredefinedAccountType)
    func showCreateWallet(predefinedAccountType: PredefinedAccountType)
    func showRestore(predefinedAccountType: PredefinedAccountType)
    func showSettings()
}

protocol IManageAccountsView: class {
    func set(viewItems: [ManageAccountViewItem])
    func showDoneButton()
    func show(error: Error)
    func showCreateConfirmation(title: String, coinCodes: String)
    func showSuccess()
    func showBackupRequired(predefinedAccountType: IPredefinedAccountType)
}

protocol IManageAccountsViewDelegate {
    func viewDidLoad()

    func didTapUnlink(index: Int)
    func didTapBackup(index: Int)
    func didTapShowKey(index: Int)
    func didTapCreate(index: Int)
    func didTapRestore(index: Int)

    func didConfirmCreate()
    func didRequestBackup()

    func didTapDone()
}

protocol IManageAccountsInteractor {
    var predefinedAccountTypes: [IPredefinedAccountType] { get }
    func account(predefinedAccountType: IPredefinedAccountType) -> Account?
    func createAccount(predefinedAccountType: IPredefinedAccountType) throws
    func restoreAccount(accountType: AccountType, syncMode: SyncMode?)
}

protocol IManageAccountsInteractorDelegate: class {
    func didUpdateAccounts()
}

protocol IManageAccountsRouter {
    func showUnlink(account: Account, predefinedAccountType: IPredefinedAccountType)
    func showBackup(account: Account, predefinedAccountType: IPredefinedAccountType)
    func showKey(account: Account)
    func showRestore(defaultAccountType: DefaultAccountType, delegate: IRestoreAccountTypeDelegate)
    func close()
}

struct ManageAccountItem {
    let predefinedAccountType: IPredefinedAccountType
    let account: Account?
}

struct ManageAccountViewItem {
    let title: String
    let coinCodes: String
    let highlighted: Bool
    let leftButtonState: ManageAccountLeftButtonState
    let rightButtonState: ManageAccountRightButtonState
}

enum ManageAccountLeftButtonState {
    case create
    case delete
}

enum ManageAccountRightButtonState {
    case backup
    case show
    case restore
}

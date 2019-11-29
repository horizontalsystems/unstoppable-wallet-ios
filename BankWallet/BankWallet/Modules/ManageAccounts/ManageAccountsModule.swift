protocol IManageAccountsView: class {
    func set(viewItems: [ManageAccountViewItem])
    func showDoneButton()
    func show(error: Error)
    func showSuccess()
    func showBackupRequired(predefinedAccountType: PredefinedAccountType)
}

protocol IManageAccountsViewDelegate {
    func viewDidLoad()

    func didTapUnlink(index: Int)
    func didTapBackup(index: Int)
    func didTapCreate(index: Int)
    func didTapRestore(index: Int)

    func didRequestBackup()

    func didTapDone()
}

protocol IManageAccountsInteractor {
    var predefinedAccountTypes: [PredefinedAccountType] { get }
    func account(predefinedAccountType: PredefinedAccountType) -> Account?
}

protocol IManageAccountsInteractorDelegate: class {
    func didUpdateAccounts()
}

protocol IManageAccountsRouter {
    func showUnlink(account: Account, predefinedAccountType: PredefinedAccountType)
    func showBackup(account: Account, predefinedAccountType: PredefinedAccountType)
    func showCreateWallet(predefinedAccountType: PredefinedAccountType)
    func showRestore(predefinedAccountType: PredefinedAccountType)
    func close()
}

struct ManageAccountItem {
    let predefinedAccountType: PredefinedAccountType
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
    case create(enabled: Bool)
    case delete
}

enum ManageAccountRightButtonState {
    case backup
    case show
    case restore
}

protocol IRestoreView: class {
    func set(accountTypes: [AccountTypeViewItem])
}

protocol IRestoreViewDelegate {
    func viewDidLoad()
    func didSelect(index: Int)
}

protocol IRestoreRouter {
    func showRestore(predefinedAccountType: PredefinedAccountType)
}

protocol IRestoreDelegate: AnyObject {
    func didRestore(account: Account)
}

protocol IRestoreAccountTypeRouter {
    func showSelectCoins(accountType: AccountType)
    func showScanQr(delegate: IScanQrModuleDelegate)
    func dismiss()
}

protocol IRestoreAccountTypeHandler {
    var selectCoins: Bool { get }

    func handle(accountType: AccountType)
    func handleScanQr(delegate: IScanQrModuleDelegate)
    func handleCancel()
}

struct AccountTypeViewItem {
    let title: String
    let coinCodes: String
}

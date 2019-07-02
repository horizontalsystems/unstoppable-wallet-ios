protocol IManageAccountsView: class {
    func reload()
}

protocol IManageAccountsViewDelegate {
    func viewDidLoad()
    var itemsCount: Int { get }
    func item(index: Int) -> Account

    func didTapUnlink(index: Int)
    func didTapBackup(index: Int)
}

protocol IManageAccountsInteractor {
    var accounts: [Account] { get }
}

protocol IManageAccountsInteractorDelegate: class {
    func didUpdate(accounts: [Account])
}

protocol IManageAccountsRouter {
    func showUnlink(accountId: String)
    func showBackup(account: Account)
}

//struct AccountViewItem {
//    let title: String
//    let coinCodes: String
//}

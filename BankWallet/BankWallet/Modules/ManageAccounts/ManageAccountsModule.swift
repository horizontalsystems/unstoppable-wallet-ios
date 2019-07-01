protocol IManageAccountsView: class {
    func show(accounts: [Account])
}

protocol IManageAccountsViewDelegate {
    func viewDidLoad()
}

protocol IManageAccountsInteractor {
    var accounts: [Account] { get }
}

protocol IManageAccountsInteractorDelegate: class {
}

protocol IManageAccountsRouter {
}

struct AccountViewItem {
    let title: String
    let coinCodes: String
}

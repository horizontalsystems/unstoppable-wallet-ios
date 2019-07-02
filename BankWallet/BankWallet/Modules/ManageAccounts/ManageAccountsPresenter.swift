class ManageAccountsPresenter {
    private let interactor: IManageAccountsInteractor
    private let router: IManageAccountsRouter

    weak var view: IManageAccountsView?

    private var accounts: [Account] = []

    init(interactor: IManageAccountsInteractor, router: IManageAccountsRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension ManageAccountsPresenter: IManageAccountsViewDelegate {

    func viewDidLoad() {
        self.accounts = interactor.accounts
    }

    var itemsCount: Int {
        return accounts.count
    }

    func item(index: Int) -> Account {
        return accounts[index]
    }

    func didTapUnlink(index: Int) {
        router.showUnlink(accountId: accounts[index].id)
    }

    func didTapBackup(index: Int) {
        router.showBackup(account: accounts[index])
    }

}

extension ManageAccountsPresenter: IManageAccountsInteractorDelegate {

    func didUpdate(accounts: [Account]) {
        self.accounts = accounts
        view?.reload()
    }

}

class ManageAccountsPresenter {
    weak var view: IManageAccountsView?

    private let interactor: IManageAccountsInteractor
    private let router: IManageAccountsRouter

    private var viewItemFactory = ManageAccountsViewItemFactory()

    private var items = [ManageAccountItem]()

    init(interactor: IManageAccountsInteractor, router: IManageAccountsRouter) {
        self.interactor = interactor
        self.router = router
    }

    private func buildItems() {
        items = interactor.predefinedAccountTypes.map {
            ManageAccountItem(predefinedAccountType: $0, account: interactor.account(predefinedAccountType: $0))
        }
    }

}

extension ManageAccountsPresenter: IManageAccountsViewDelegate {

    func viewDidLoad() {
        buildItems()
    }

    var itemsCount: Int {
        return items.count
    }

    func item(index: Int) -> ManageAccountViewItem {
        return viewItemFactory.viewItem(item: items[index])
    }

    func didTapUnlink(index: Int) {
//        router.showUnlink(accountId: accounts[index].id)
    }

    func didTapBackup(index: Int) {
//        router.showBackup(account: accounts[index])
    }

    func didTapShowKey(index: Int) {

    }

    func didTapCreate(index: Int) {
    }

    func didTapRestore(index: Int) {
    }

}

extension ManageAccountsPresenter: IManageAccountsInteractorDelegate {

    func didUpdateAccounts() {
        buildItems()
        view?.reload()
    }

}

class ManageAccountsPresenter {
    weak var view: IManageAccountsView?

    private let mode: ManageAccountsRouter.PresentationMode
    private let interactor: IManageAccountsInteractor
    private let router: IManageAccountsRouter

    private var viewItemFactory = ManageAccountsViewItemFactory()

    private var items = [ManageAccountItem]()

    init(mode: ManageAccountsRouter.PresentationMode, interactor: IManageAccountsInteractor, router: IManageAccountsRouter) {
        self.mode = mode
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
        if mode == .presented {
            view?.showDoneButton()
        }

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

    func didTapDone() {
        router.close()
    }

}

extension ManageAccountsPresenter: IManageAccountsInteractorDelegate {

    func didUpdateAccounts() {
        buildItems()
        view?.reload()
    }

}

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
        guard let account = items[index].account else {
            return
        }

        router.showUnlink(accountId: account.id)
    }

    func didTapBackup(index: Int) {
        guard let account = items[index].account else {
            return
        }

        router.showBackup(account: account)
    }

    func didTapShowKey(index: Int) {
        guard let account = items[index].account else {
            return
        }

        router.showKey(account: account)
    }

    func didTapCreate(index: Int) {
        do {
            try interactor.createAccount(predefinedAccountType: items[index].predefinedAccountType)
        } catch {
            view?.show(error: error)
        }
    }

    func didTapRestore(index: Int) {
        router.showRestore(predefinedAccountType: items[index].predefinedAccountType, delegate: self)
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

extension ManageAccountsPresenter: IRestoreAccountTypeDelegate {

    func didRestore(accountType: AccountType, syncMode: SyncMode?) {
        interactor.restoreAccount(accountType: accountType, syncMode: syncMode)
    }

}

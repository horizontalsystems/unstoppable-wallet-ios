class ManageAccountsPresenter {
    weak var view: IManageAccountsView?

    private let mode: ManageAccountsRouter.PresentationMode
    private let interactor: IManageAccountsInteractor
    private let router: IManageAccountsRouter

    private var viewItemFactory = ManageAccountsViewItemFactory()

    private var items = [ManageAccountItem]()
    private var currentItem: ManageAccountItem?

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
        let item = items[index]

        guard let account = item.account else {
            return
        }

        if account.backedUp {
            router.showUnlink(account: account, predefinedAccountType: item.predefinedAccountType)
        } else {
            currentItem = item
            view?.showBackupRequired(title: item.predefinedAccountType.title)
        }
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
        let item = items[index]
        currentItem = item
        view?.showCreateConfirmation(title: item.predefinedAccountType.title, coinCodes: item.predefinedAccountType.coinCodes)
    }

    func didTapRestore(index: Int) {
        router.showRestore(defaultAccountType: items[index].predefinedAccountType.defaultAccountType, delegate: self)
    }

    func didConfirmCreate() {
        guard let item = currentItem else {
            return
        }

        do {
            try interactor.createAccount(predefinedAccountType: item.predefinedAccountType)
            view?.showSuccess()
        } catch {
            view?.show(error: error)
        }
    }

    func didTapDone() {
        router.close()
    }

    func didRequestBackup() {
        guard let item = currentItem, let account = item.account else {
            return
        }

        router.showBackup(account: account)
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

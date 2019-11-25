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

    private func updateView() {
        view?.set(viewItems: items.map { self.viewItemFactory.viewItem(item: $0) })
    }

}

extension ManageAccountsPresenter: IManageAccountsViewDelegate {

    func viewDidLoad() {
        if mode == .presented {
            view?.showDoneButton()
        }

        buildItems()
        updateView()
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
            view?.showBackupRequired(predefinedAccountType: item.predefinedAccountType)
        }
    }

    func didTapBackup(index: Int) {
        let item = items[index]

        guard let account = item.account else {
            return
        }

        router.showBackup(account: account, predefinedAccountType: item.predefinedAccountType)
    }

    func didTapCreate(index: Int) {
        let item = items[index]
        currentItem = item
        router.showCreateWallet(predefinedAccountType: item.predefinedAccountType)
    }

    func didTapRestore(index: Int) {
        router.showRestore(predefinedAccountType: items[index].predefinedAccountType)
    }

    func didTapDone() {
        router.close()
    }

    func didRequestBackup() {
        guard let item = currentItem, let account = item.account else {
            return
        }

        router.showBackup(account: account, predefinedAccountType: item.predefinedAccountType)
    }

}

extension ManageAccountsPresenter: IManageAccountsInteractorDelegate {

    func didUpdateAccounts() {
        buildItems()
        updateView()
    }

}

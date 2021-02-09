class ManageAccountsPresenter {
    weak var view: IManageAccountsView?

    private let interactor: IManageAccountsInteractor
    private let router: IManageAccountsRouter

    private var viewItemFactory = ManageAccountsViewItemFactory()

    private var items = [ManageAccountItem]()

    private var hasAddressFormatSettings = false

    init(interactor: IManageAccountsInteractor, router: IManageAccountsRouter) {
        self.interactor = interactor
        self.router = router
    }

    private func buildItems() {
        items = interactor.predefinedAccountTypes.map {
            ManageAccountItem(predefinedAccountType: $0, account: interactor.account(predefinedAccountType: $0))
        }
    }

    private func updateView() {
        view?.set(viewItems: items.map { self.viewItemFactory.viewItem(item: $0, hasAddressFormatSettings: hasAddressFormatSettings) })
    }

    private func syncAddressFormatSettings() {
        hasAddressFormatSettings = interactor.hasAddressFormatSettings
    }

}

extension ManageAccountsPresenter: IManageAccountsViewDelegate {

    func viewDidLoad() {
        buildItems()
        syncAddressFormatSettings()
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
            router.showBackupRequired(account: account, predefinedAccountType: item.predefinedAccountType)
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
        router.showCreateWallet(predefinedAccountType: item.predefinedAccountType)
    }

    func didTapRestore(index: Int) {
        router.showRestore(predefinedAccountType: items[index].predefinedAccountType)
    }

    func didTapSettings(index: Int) {
        router.showSettings()
    }

}

extension ManageAccountsPresenter: IManageAccountsInteractorDelegate {

    func didUpdateAccounts() {
        buildItems()
        updateView()
    }

    func didUpdateWallets() {
        syncAddressFormatSettings()
        updateView()
    }

}

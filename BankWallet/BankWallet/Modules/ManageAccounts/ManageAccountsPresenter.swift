class ManageAccountsPresenter {
    weak var view: IManageAccountsView?

    private let interactor: IManageAccountsInteractor
    private let router: IManageAccountsRouter

    private var viewItemFactory = ManageAccountsViewItemFactory()
    private let restoreSequenceManager: IRestoreSequenceManager

    private var items = [ManageAccountItem]()
    private var currentItem: ManageAccountItem?

    private var predefinedAccountType: PredefinedAccountType?
    private var accountType: AccountType?
    private var coins: [Coin]?

    init(interactor: IManageAccountsInteractor, router: IManageAccountsRouter, restoreSequenceManager: IRestoreSequenceManager) {
        self.interactor = interactor
        self.router = router
        self.restoreSequenceManager = restoreSequenceManager
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
        predefinedAccountType = items[index].predefinedAccountType
        router.showRestore(predefinedAccountType: items[index].predefinedAccountType, delegate: self)
    }

    func didTapSettings(index: Int) {
        let item = items[index]

        guard let account = item.account else {
            return
        }

        router.showSettings(coins: interactor.wallets.filter { $0.account == account}.map { $0.coin })
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

extension ManageAccountsPresenter: ICredentialsCheckDelegate {

    func didCheck(accountType: AccountType) {
        self.accountType = accountType

        restoreSequenceManager.onAccountCheck(accountType: accountType, predefinedAccountType: predefinedAccountType, coins: { [unowned self] accountType, predefinedAccountType in
            router.showRestoreCoins(predefinedAccountType: predefinedAccountType, accountType: accountType, delegate: self)
        })
    }

}

extension ManageAccountsPresenter: IRestoreCoinsDelegate {

    func onSelect(coins: [Coin], derivationSettings: [DerivationSetting]) {
        self.coins = coins

        restoreSequenceManager.onCoinsSelect(coins: coins, accountType: accountType, derivationSettings: derivationSettings, finish: {
            router.closeRestore()
        })
    }

}

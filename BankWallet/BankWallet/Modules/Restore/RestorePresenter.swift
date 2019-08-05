class RestorePresenter {
    weak var view: IRestoreView?

    private let router: IRestoreRouter
    private let accountCreator: IAccountCreator
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager

    private var predefinedAccountTypes = [IPredefinedAccountType]()

    init(router: IRestoreRouter, accountCreator: IAccountCreator, predefinedAccountTypeManager: IPredefinedAccountTypeManager) {
        self.router = router
        self.accountCreator = accountCreator
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
    }

}

extension RestorePresenter: IRestoreViewDelegate {

    func viewDidLoad() {
        predefinedAccountTypes = predefinedAccountTypeManager.allTypes
    }

    var typesCount: Int {
        return predefinedAccountTypes.count
    }

    func type(index: Int) -> IPredefinedAccountType {
        return predefinedAccountTypes[index]
    }

    func didSelect(index: Int) {
        router.showRestore(defaultAccountType: predefinedAccountTypes[index].defaultAccountType, delegate: self)
    }

    func didTapCancel() {
        router.close()
    }

}

extension RestorePresenter: IRestoreAccountTypeDelegate {

    func didRestore(accountType: AccountType, syncMode: SyncMode?) {
        let account = accountCreator.createRestoredAccount(accountType: accountType, defaultSyncMode: syncMode, createDefaultWallets: true)

        router.notifyRestored(account: account)
        router.close()
    }

}

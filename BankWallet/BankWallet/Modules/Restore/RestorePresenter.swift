class RestorePresenter {
    weak var view: IRestoreView?

    private let router: IRestoreRouter
    private let accountCreator: IAccountCreator
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager
    private let viewItemsFactory: AccountTypeViewItemFactory

    private var predefinedAccountTypes = [PredefinedAccountType]()

    private var predefinedAccountType: PredefinedAccountType?
    private var accountType: AccountType?

    init(router: IRestoreRouter, accountCreator: IAccountCreator, predefinedAccountTypeManager: IPredefinedAccountTypeManager, viewItemsFactory: AccountTypeViewItemFactory = .init()) {
        self.router = router
        self.accountCreator = accountCreator
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
        self.viewItemsFactory = viewItemsFactory
    }

}

extension RestorePresenter: IRestoreViewDelegate {

    func viewDidLoad() {
        predefinedAccountTypes = predefinedAccountTypeManager.allTypes
        view?.set(accountTypes: viewItemsFactory.viewItems(accountTypes: predefinedAccountTypes))
    }

    func didSelect(index: Int) {
        predefinedAccountType = predefinedAccountTypes[index]

        router.showRestore(predefinedAccountType: predefinedAccountTypes[index], delegate: self)
    }

}

extension RestorePresenter: ICredentialsCheckDelegate {

    func didCheck(accountType: AccountType) {
        self.accountType = accountType
        guard let predefinedAccountType = predefinedAccountType else {
            return
        }

        if predefinedAccountType == .standard {
            router.showSettings(delegate: self)
        } else {
            router.showRestoreCoins(predefinedAccountType: predefinedAccountType, accountType: accountType, delegate: self)
        }
    }

}

extension RestorePresenter: ICoinSettingsDelegate {

    func onSelect() {
        guard let accountType = accountType else {
            return
        }
        guard let predefinedAccountType = predefinedAccountType else {
            return
        }

        router.showRestoreCoins(predefinedAccountType: predefinedAccountType, accountType: accountType, delegate: self)
    }

}

extension RestorePresenter: IRestoreCoinsDelegate {

    func didRestore() {
        router.showMain()
    }

}

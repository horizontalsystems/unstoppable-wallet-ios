class RestorePresenter {
    weak var view: IRestoreView?

    private let router: IRestoreRouter
    private let accountCreator: IAccountCreator
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager
    private let viewItemsFactory: AccountTypeViewItemFactory

    private var predefinedAccountTypes = [PredefinedAccountType]()

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
        router.showRestoreCoins(predefinedAccountType: predefinedAccountTypes[index])
    }

}

class RestorePresenter {
    weak var view: IRestoreView?

    private let router: IRestoreRouter
    private let accountCreator: IAccountCreator
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager
    private let viewItemsFactory: AccountTypeViewItemFactory
    private let restoreSequenceFactory: IRestoreSequenceFactory

    private var predefinedAccountTypes = [PredefinedAccountType]()

    private var predefinedAccountType: PredefinedAccountType?
    private var accountType: AccountType?

    init(router: IRestoreRouter, accountCreator: IAccountCreator, predefinedAccountTypeManager: IPredefinedAccountTypeManager, viewItemsFactory: AccountTypeViewItemFactory = .init(), restoreSequenceFactory: IRestoreSequenceFactory = RestoreSequenceFactory()) {
        self.router = router
        self.accountCreator = accountCreator
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
        self.viewItemsFactory = viewItemsFactory
        self.restoreSequenceFactory = restoreSequenceFactory
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

        restoreSequenceFactory.onAccountCheck(accountType: accountType, predefinedAccountType: predefinedAccountType, settings: { [unowned self] in
                    router.showSettings(delegate: self)
                }, coins: { [unowned self] accountType, predefinedAccountType in
                    router.showRestoreCoins(predefinedAccountType: predefinedAccountType, accountType: accountType, delegate: self)
                }
        )
    }

}

extension RestorePresenter: IBlockchainSettingsDelegate {

    func onConfirm() {
        restoreSequenceFactory.onSettingsConfirm(accountType: accountType, predefinedAccountType: predefinedAccountType, coins: { [unowned self] accountType, predefinedAccountType in
            router.showRestoreCoins(predefinedAccountType: predefinedAccountType, accountType: accountType, delegate: self)
        })
    }

}

extension RestorePresenter: IRestoreCoinsDelegate {

    func didRestore() {
        router.showMain()
    }

}

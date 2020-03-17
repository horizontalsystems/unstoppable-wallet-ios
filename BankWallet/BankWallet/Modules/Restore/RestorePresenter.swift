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
    private var coins: [Coin]?

    init(router: IRestoreRouter, accountCreator: IAccountCreator, predefinedAccountTypeManager: IPredefinedAccountTypeManager, viewItemsFactory: AccountTypeViewItemFactory = .init(), restoreSequenceFactory: IRestoreSequenceFactory) {
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

        restoreSequenceFactory.onAccountCheck(accountType: accountType, predefinedAccountType: predefinedAccountType, coins: { [weak self] accountType, predefinedAccountType, proceedMode in
            router.showRestoreCoins(predefinedAccountType: predefinedAccountType, accountType: accountType, proceedMode: proceedMode, delegate: self)
        })
    }

}

extension RestorePresenter: IBlockchainSettingsDelegate {

    func onConfirm(settings: [BlockchainSetting]) {
        restoreSequenceFactory.onSettingsConfirm(accountType: accountType, coins: coins, settings: settings, success: {
            router.showMain()
        })
    }

}

extension RestorePresenter: IRestoreCoinsDelegate {

    func onSelect(coins: [Coin]) {
        self.coins = coins

        restoreSequenceFactory.onCoinsSelect(coins: coins, accountType: accountType, predefinedAccountType: predefinedAccountType, settings: { [weak self] in
            self?.router.showSettings(coins: coins, delegate: self)
        }, finish: { [weak self] in
            self?.router.showMain()
        })
    }

}

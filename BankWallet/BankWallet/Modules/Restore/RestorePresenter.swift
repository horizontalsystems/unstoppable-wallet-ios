class RestorePresenter {
    weak var view: IRestoreView?

    private let router: IRestoreRouter
    private let accountCreator: IAccountCreator
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager
    private let viewItemsFactory: AccountTypeViewItemFactory
    private let restoreSequenceManager: IRestoreSequenceManager

    private var predefinedAccountTypes = [PredefinedAccountType]()

    private var predefinedAccountType: PredefinedAccountType?
    private var accountType: AccountType?
    private var coins: [Coin]?

    init(router: IRestoreRouter, accountCreator: IAccountCreator, predefinedAccountTypeManager: IPredefinedAccountTypeManager, viewItemsFactory: AccountTypeViewItemFactory = .init(), restoreSequenceFactory: IRestoreSequenceManager) {
        self.router = router
        self.accountCreator = accountCreator
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
        self.viewItemsFactory = viewItemsFactory
        self.restoreSequenceManager = restoreSequenceFactory
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

        restoreSequenceManager.onAccountCheck(accountType: accountType, predefinedAccountType: predefinedAccountType, coins: { [weak self] accountType, predefinedAccountType in
            router.showRestoreCoins(predefinedAccountType: predefinedAccountType, accountType: accountType, delegate: self)
        })
    }

}

//extension RestorePresenter: IDerivationSettingsDelegate {
//
////    func onConfirm(settings: [DerivationSetting]) {
////        restoreSequenceManager.onSettingsConfirm(accountType: accountType, coins: coins, derivationSettings: settings, success: {
////            router.showMain()
////        })
////    }
//
//}

extension RestorePresenter: IRestoreCoinsDelegate {
    func onSelect(coins: [Coin], derivationSettings: [DerivationSetting]) {
        self.coins = coins

        restoreSequenceManager.onCoinsSelect(coins: coins, accountType: accountType, derivationSettings: derivationSettings, finish: { [weak self] in
            self?.router.showMain()
        })
//        restoreSequenceManager.onCoinsSelect(coins: coins, accountType: accountType, settings: { [weak self] in
////            self?.router.showSettings(coins: coins, delegate: self)
//        }, finish: { [weak self] in
//            self?.router.showMain()
//        })
    }

}

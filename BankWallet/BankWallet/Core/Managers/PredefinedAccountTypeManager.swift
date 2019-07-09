class PredefinedAccountTypeManager {
    private let appConfigProvider: IAppConfigProvider
    private let accountManager: IAccountManager

    init(appConfigProvider: IAppConfigProvider, accountManager: IAccountManager) {
        self.appConfigProvider = appConfigProvider
        self.accountManager = accountManager
    }

}

extension PredefinedAccountTypeManager: IPredefinedAccountTypeManager {

    var allTypes: [IPredefinedAccountType] {
        return appConfigProvider.predefinedAccountTypes
    }

}

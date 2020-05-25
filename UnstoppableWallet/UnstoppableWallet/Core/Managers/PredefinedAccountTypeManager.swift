class PredefinedAccountTypeManager {
    private let appConfigProvider: IAppConfigProvider
    private let accountManager: IAccountManager

    init(appConfigProvider: IAppConfigProvider, accountManager: IAccountManager) {
        self.appConfigProvider = appConfigProvider
        self.accountManager = accountManager
    }

}

extension PredefinedAccountTypeManager: IPredefinedAccountTypeManager {

    var allTypes: [PredefinedAccountType] {
        PredefinedAccountType.allCases
    }

    func account(predefinedAccountType: PredefinedAccountType) -> Account? {
        accountManager.accounts.first { predefinedAccountType.supports(accountType: $0.type) }
    }

    func predefinedAccountType(accountType: AccountType) -> PredefinedAccountType? {
        allTypes.first { $0.supports(accountType: accountType) }
    }

}

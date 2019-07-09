class PredefinedAccountTypeManager {
    private let accountManager: IAccountManager

    private let types: [IPredefinedAccountType] = [
        Words12AccountType()
    ]

    init(accountManager: IAccountManager) {
        self.accountManager = accountManager
    }

}

extension PredefinedAccountTypeManager: IPredefinedAccountTypeManager {

    var allTypes: [IPredefinedAccountType] {
        return types
    }

    func account(predefinedAccountType: IPredefinedAccountType) -> Account? {
        return nil
    }

}

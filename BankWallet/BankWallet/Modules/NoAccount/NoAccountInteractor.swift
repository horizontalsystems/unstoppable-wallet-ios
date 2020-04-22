class NoAccountInteractor {
    private let accountManager: IAccountManager
    private let accountCreator: IAccountCreator

    init(accountManager: IAccountManager, accountCreator: IAccountCreator) {
        self.accountManager = accountManager
        self.accountCreator = accountCreator
    }

}

extension NoAccountInteractor: INoAccountInteractor {

    func createAccount(predefinedAccountType: PredefinedAccountType) throws -> Account {
        try accountCreator.newAccount(predefinedAccountType: predefinedAccountType)
    }

    func save(account: Account) {
        accountManager.save(account: account)
    }

}

class AccountCreator {
    private let accountManager: IAccountManager
    private let accountFactory: IAccountFactory

    init(accountManager: IAccountManager, accountFactory: IAccountFactory) {
        self.accountManager = accountManager
        self.accountFactory = accountFactory
    }

    private func createAccount(accountType: AccountType, backedUp: Bool, defaultSyncMode: SyncMode?) -> Account {
        let account = accountFactory.account(
                type: accountType,
                backedUp: backedUp,
                defaultSyncMode: defaultSyncMode
        )

        accountManager.create(account: account)

        return account
    }

}

extension AccountCreator: IAccountCreator {

    func createNewAccount(accountType: AccountType) -> Account {
        return createAccount(accountType: accountType, backedUp: false, defaultSyncMode: .new)
    }

    func createRestoredAccount(accountType: AccountType, syncMode: SyncMode?) -> Account {
        return createAccount(accountType: accountType, backedUp: true, defaultSyncMode: syncMode)
    }

}

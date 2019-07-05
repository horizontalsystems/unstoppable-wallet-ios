class AccountCreator {
    private let accountManager: IAccountManager
    private let accountFactory: IAccountFactory

    init(accountManager: IAccountManager, accountFactory: IAccountFactory) {
        self.accountManager = accountManager
        self.accountFactory = accountFactory
    }

}

extension AccountCreator: IAccountCreator {

    func createRestoredAccount(accountType: AccountType, syncMode: SyncMode?) {
        let account = accountFactory.account(
                type: accountType,
                backedUp: true,
                defaultSyncMode: syncMode
        )

        accountManager.save(account: account)
    }

}

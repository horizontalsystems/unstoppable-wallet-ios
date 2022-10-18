class WatchService {
    private let accountFactory: AccountFactory
    private let accountManager: AccountManager

    init(accountFactory: AccountFactory, accountManager: AccountManager) {
        self.accountFactory = accountFactory
        self.accountManager = accountManager
    }

}

extension WatchService {

    func watch(accountType: AccountType, name: String?) {
        let account = accountFactory.watchAccount(type: accountType, name: name)
        accountManager.save(account: account)
    }

}

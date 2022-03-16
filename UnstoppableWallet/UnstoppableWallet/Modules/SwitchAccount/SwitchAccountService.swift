class SwitchAccountService {
    private let accountManager: AccountManager

    init(accountManager: AccountManager) {
        self.accountManager = accountManager
    }

}

extension SwitchAccountService {

    var items: [Item] {
        let activeAccount = accountManager.activeAccount
        return accountManager.accounts.map { account in
            Item(account: account, isActive: account == activeAccount)
        }
    }

    func set(activeAccountId: String) {
        accountManager.set(activeAccountId: activeAccountId)
    }

}

extension SwitchAccountService {

    struct Item {
        let account: Account
        let isActive: Bool
    }

}

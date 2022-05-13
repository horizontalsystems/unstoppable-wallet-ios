class UnlinkService {
    let account: Account
    private let accountManager: AccountManager

    init(account: Account, accountManager: AccountManager) {
        self.account = account
        self.accountManager = accountManager
    }

}

extension UnlinkService {

    func deleteAccount() {
        accountManager.delete(account: account)
    }

}

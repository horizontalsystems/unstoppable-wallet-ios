class UnlinkService {
    let account: Account
    private let accountManager: IAccountManager

    init(account: Account, accountManager: IAccountManager) {
        self.account = account
        self.accountManager = accountManager
    }

}

extension UnlinkService {

    func deleteAccount() {
        accountManager.delete(account: account)
    }

}

class UnlinkInteractor {
    private let accountManager: IAccountManager

    init(accountManager: IAccountManager) {
        self.accountManager = accountManager
    }

}

extension UnlinkInteractor: IUnlinkInteractor {

    func delete(account: Account) {
        accountManager.delete(account: account)
    }

}

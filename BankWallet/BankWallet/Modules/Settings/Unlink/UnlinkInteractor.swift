class UnlinkInteractor {
    weak var delegate: IUnlinkInteractorDelegate?

    private let accountManager: IAccountManager

    init(accountManager: IAccountManager) {
        self.accountManager = accountManager
    }

}

extension UnlinkInteractor: IUnlinkInteractor {

    func unlink(account: Account) {
        accountManager.delete(account: account)
    }

}

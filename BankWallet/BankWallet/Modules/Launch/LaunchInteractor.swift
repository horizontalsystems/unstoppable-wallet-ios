class LaunchInteractor {
    private let accountManager: IAccountManager
    private let pinManager: IPinManager
    private let passcodeLockManager: IPasscodeLockManager

    init(accountManager: IAccountManager, pinManager: IPinManager, passcodeLockManager: IPasscodeLockManager) {
        self.accountManager = accountManager
        self.pinManager = pinManager
        self.passcodeLockManager = passcodeLockManager
    }

}

extension LaunchInteractor: ILaunchInteractor {

    var passcodeLocked: Bool {
        return passcodeLockManager.locked
    }

    var hasAccounts: Bool {
        return !accountManager.accounts.isEmpty
    }

    var isPinSet: Bool {
        return pinManager.isPinSet
    }

}

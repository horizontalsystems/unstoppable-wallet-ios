class LaunchInteractor {
    private let accountManager: IAccountManager
    private let pinManager: IPinManager
    private let passcodeLockManager: IPasscodeLockManager
    private let localStorage: ILocalStorage

    init(accountManager: IAccountManager, pinManager: IPinManager, passcodeLockManager: IPasscodeLockManager, localStorage: ILocalStorage) {
        self.accountManager = accountManager
        self.pinManager = pinManager
        self.passcodeLockManager = passcodeLockManager
        self.localStorage = localStorage
    }

}

extension LaunchInteractor: ILaunchInteractor {

    var hasAccounts: Bool {
        return !accountManager.accounts.isEmpty
    }

    var passcodeLocked: Bool {
        return passcodeLockManager.locked
    }

    var isPinSet: Bool {
        return pinManager.isPinSet
    }

    var mainShownOnce: Bool {
        return localStorage.mainShownOnce
    }

}

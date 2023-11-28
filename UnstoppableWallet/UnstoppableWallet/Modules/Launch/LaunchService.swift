class LaunchService {
    private let accountManager: AccountManager
    private let passcodeManager: PasscodeManager
    private let passcodeLockManager: PasscodeLockManager
    private let localStorage: LocalStorage

    init(accountManager: AccountManager, passcodeManager: PasscodeManager, passcodeLockManager: PasscodeLockManager, localStorage: LocalStorage) {
        self.accountManager = accountManager
        self.passcodeManager = passcodeManager
        self.passcodeLockManager = passcodeLockManager
        self.localStorage = localStorage
    }
}

extension LaunchService {
    var launchMode: LaunchModule.LaunchMode {
        let passcodeLockState = passcodeLockManager.state

        if passcodeLockState == .passcodeNotSet {
            return .passcodeNotSet
        } else if passcodeLockState == .unknown {
            return .cannotCheckPasscode
        } else if passcodeManager.isPasscodeSet {
            return .unlock
        } else if accountManager.accounts.isEmpty, !localStorage.mainShownOnce {
            return .intro
        } else {
            return .main
        }
    }
}

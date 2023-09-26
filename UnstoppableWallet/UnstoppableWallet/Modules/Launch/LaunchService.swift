import StorageKit

class LaunchService {
    private let accountManager: AccountManager
    private let passcodeManager: PasscodeManager
    private let keychainKit: IKeychainKit
    private let localStorage: LocalStorage

    init(accountManager: AccountManager, passcodeManager: PasscodeManager, keychainKit: IKeychainKit, localStorage: LocalStorage) {
        self.accountManager = accountManager
        self.passcodeManager = passcodeManager
        self.keychainKit = keychainKit
        self.localStorage = localStorage
    }
}

extension LaunchService {
    var launchMode: LaunchModule.LaunchMode {
        let passcodeLockState = keychainKit.passcodeLockState

        if passcodeLockState == .passcodeNotSet {
            return .passcodeNotSet
        } else if passcodeLockState == .unknown {
            return .cannotCheckPasscode
        } else if passcodeManager.isPasscodeSet {
            return .unlock
        } else if accountManager.accounts.isEmpty && !localStorage.mainShownOnce {
            return .intro
        } else {
            return .main
        }
    }
}

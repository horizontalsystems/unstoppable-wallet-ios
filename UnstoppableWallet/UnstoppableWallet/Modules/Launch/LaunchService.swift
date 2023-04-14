import StorageKit
import PinKit

class LaunchService {
    private let accountManager: AccountManager
    private let pinKit: IPinKit
    private let keychainKit: IKeychainKit
    private let localStorage: LocalStorage

    init(accountManager: AccountManager, pinKit: IPinKit, keychainKit: IKeychainKit, localStorage: LocalStorage) {
        self.accountManager = accountManager
        self.pinKit = pinKit
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
        } else if pinKit.isPinSet {
            return .unlock
        } else if accountManager.accounts.isEmpty && !localStorage.mainShownOnce {
            return  .intro
        } else {
            return .main
        }

    }

}

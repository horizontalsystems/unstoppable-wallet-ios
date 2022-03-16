import StorageKit
import PinKit

class LaunchInteractor {
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

extension LaunchInteractor: ILaunchInteractor {

    var hasAccounts: Bool {
        !accountManager.accounts.isEmpty
    }

    var passcodeLocked: Bool {
        keychainKit.locked
    }

    var isPinSet: Bool {
        pinKit.isPinSet
    }

    var mainShownOnce: Bool {
        localStorage.mainShownOnce
    }

}

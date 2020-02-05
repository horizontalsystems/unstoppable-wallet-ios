import StorageKit

class LaunchInteractor {
    private let accountManager: IAccountManager
    private let pinManager: IPinManager
    private let keychainKit: IKeychainKit
    private let localStorage: ILocalStorage

    init(accountManager: IAccountManager, pinManager: IPinManager, keychainKit: IKeychainKit, localStorage: ILocalStorage) {
        self.accountManager = accountManager
        self.pinManager = pinManager
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
        pinManager.isPinSet
    }

    var mainShownOnce: Bool {
        localStorage.mainShownOnce
    }

}

import StorageKit
import PinKit

class LaunchInteractor {
    private let accountManager: IAccountManager
    private let pinKit: IPinKit
    private let keychainKit: IKeychainKit
    private let localStorage: ILocalStorage
    private let jailbreakTestManager: JailbreakTestManager

    init(accountManager: IAccountManager, pinKit: IPinKit, keychainKit: IKeychainKit, localStorage: ILocalStorage, jailbreakTestManager: JailbreakTestManager) {
        self.accountManager = accountManager
        self.pinKit = pinKit
        self.keychainKit = keychainKit
        self.localStorage = localStorage
        self.jailbreakTestManager = jailbreakTestManager
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

    var jailbroken: Bool {
        jailbreakTestManager.isJailbroken
    }

}

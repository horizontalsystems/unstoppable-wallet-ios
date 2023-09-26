import Combine
import Foundation
import HsExtensions
import StorageKit

class LockManager {
    private let lastExitDateKey = "last_exit_date_key"

    private let passcodeManager: PasscodeManager
    private let localStorage: ILocalStorage
    private let delegate: LockDelegate

    private let lockTimeout: Double = 60
    private(set) var isLocked: Bool


    init(passcodeManager: PasscodeManager, localStorage: ILocalStorage, delegate: LockDelegate) {
        self.passcodeManager = passcodeManager
        self.localStorage = localStorage
        self.delegate = delegate

        isLocked = passcodeManager.isPasscodeSet
    }
}

extension LockManager {
    func didEnterBackground() {
        guard !isLocked else {
            return
        }

        localStorage.set(value: Date().timeIntervalSince1970, for: lastExitDateKey)
    }

    func willEnterForeground() {
        guard !isLocked else {
            return
        }

        let exitTimestamp: TimeInterval = localStorage.value(for: lastExitDateKey) ?? 0
        let now = Date().timeIntervalSince1970

        guard now - exitTimestamp > lockTimeout else {
            return
        }

        lock()
    }

    func lock() {
        guard passcodeManager.isPasscodeSet else {
            return
        }

        isLocked = true
        delegate.onLock()
    }

    func onUnlock() {
        isLocked = false
    }
}

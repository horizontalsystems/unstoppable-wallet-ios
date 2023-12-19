import Combine
import Foundation
import HsExtensions

class LockManager {
    private let lastExitDateKey = "last_exit_date_key"
    private let autoLockPeriodKey = "auto-lock-period"

    private let passcodeManager: PasscodeManager
    private let userDefaultsStorage: UserDefaultsStorage
    private let delegate: LockDelegate

    private(set) var isLocked: Bool

    var autoLockPeriod: AutoLockPeriod {
        didSet {
            userDefaultsStorage.set(value: autoLockPeriod.rawValue, for: autoLockPeriodKey)
        }
    }

    init(passcodeManager: PasscodeManager, userDefaultsStorage: UserDefaultsStorage, delegate: LockDelegate) {
        self.passcodeManager = passcodeManager
        self.userDefaultsStorage = userDefaultsStorage
        self.delegate = delegate

        isLocked = passcodeManager.isPasscodeSet
        let autoLockPeriodRaw: String? = userDefaultsStorage.value(for: autoLockPeriodKey)
        autoLockPeriod = autoLockPeriodRaw.flatMap { AutoLockPeriod(rawValue: $0) } ?? .minute1
    }
}

extension LockManager {
    func didEnterBackground() {
        guard !isLocked else {
            return
        }

        userDefaultsStorage.set(value: Date().timeIntervalSince1970, for: lastExitDateKey)
    }

    func willEnterForeground() {
        guard !isLocked else {
            return
        }

        let exitTimestamp: TimeInterval = userDefaultsStorage.value(for: lastExitDateKey) ?? 0
        let now = Date().timeIntervalSince1970

        guard now - exitTimestamp > autoLockPeriod.period else {
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

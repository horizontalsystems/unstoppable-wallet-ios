import Combine
import Foundation
import HsExtensions
import SwiftUI

class LockManager {
    private let lastExitDateKey = "last_exit_date_key"
    private let autoLockPeriodKey = "auto-lock-period"

    private let passcodeManager: PasscodeManager
    private let userDefaultsStorage: UserDefaultsStorage

    @DistinctPublished private(set) var isLocked: Bool

    var windowScene: UIWindowScene? {
        didSet {
            lock()
        }
    }

    private var window: UIWindow?

    var autoLockPeriod: AutoLockPeriod {
        didSet {
            userDefaultsStorage.set(value: autoLockPeriod.rawValue, for: autoLockPeriodKey)
        }
    }

    init(passcodeManager: PasscodeManager, userDefaultsStorage: UserDefaultsStorage) {
        self.passcodeManager = passcodeManager
        self.userDefaultsStorage = userDefaultsStorage

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

    private func lock() {
        guard passcodeManager.isPasscodeSet else {
            return
        }

        isLocked = true

        guard let windowScene, window == nil else {
            return
        }

        let window = UIWindow(windowScene: windowScene)
        window.windowLevel = UIWindow.Level.alert - 1
        window.isHidden = false

        let hostingController = UIHostingController(rootView: AppUnlockView())
        window.rootViewController = hostingController

        self.window = window
    }

    func unlock() {
        isLocked = false

        guard window != nil else {
            return
        }

        UIView.animate(withDuration: 0.15, animations: {
            self.window?.alpha = 0
        }) { _ in
            self.window = nil
        }
    }
}

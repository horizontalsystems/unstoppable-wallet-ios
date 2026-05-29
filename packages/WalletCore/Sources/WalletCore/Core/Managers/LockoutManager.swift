import Foundation
import HsExtensions

class LockoutManager {
    private let maxAttempts = 5

    private let unlockAttemptsKey = "unlock_attempts_keychain_key"
    private let unlockUptimeKey = "unlock_uptime_keychain_key"
    private let lastKnownUptimeKey = "last_known_uptime_keychain_key"

    private var keychainStorage: KeychainStorage
    private var timer: Timer?

    @PostPublished private(set) var lockoutState: LockoutState = .unlocked(attemptsLeft: 0, maxAttempts: 0)

    private var unlockAttempts: Int {
        didSet {
            try? keychainStorage.set(value: unlockAttempts, for: unlockAttemptsKey)
        }
    }

    private var unlockUptime: TimeInterval {
        didSet {
            try? keychainStorage.set(value: unlockUptime, for: unlockUptimeKey)
        }
    }

    private var lastKnownUptime: TimeInterval {
        didSet {
            try? keychainStorage.set(value: lastKnownUptime, for: lastKnownUptimeKey)
        }
    }

    init(keychainStorage: KeychainStorage) {
        self.keychainStorage = keychainStorage

        unlockAttempts = keychainStorage.value(for: unlockAttemptsKey) ?? 0
        unlockUptime = keychainStorage.value(for: unlockUptimeKey) ?? Self.uptime
        lastKnownUptime = keychainStorage.value(for: lastKnownUptimeKey) ?? Self.uptime

        syncState()
    }

    private static var uptime: TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }

    private var lockoutInterval: TimeInterval {
        if unlockAttempts == maxAttempts {
            return 5 * 60
        } else if unlockAttempts == maxAttempts + 1 {
            return 10 * 60
        } else if unlockAttempts == maxAttempts + 2 {
            return 15 * 60
        } else {
            return 30 * 60
        }
    }
}

extension LockoutManager {
    func syncState() {
        timer?.invalidate()

        if unlockAttempts < maxAttempts {
            lockoutState = .unlocked(attemptsLeft: maxAttempts - unlockAttempts, maxAttempts: maxAttempts)
        } else {
            let uptime = Self.uptime

            // detect device reboot (when rebooted - uptime resets)
            if lastKnownUptime > uptime {
                let previousRemaining = unlockUptime - lastKnownUptime

                unlockUptime = uptime + previousRemaining
                lastKnownUptime = uptime
            }

            let timeRemaining = max(0, unlockUptime - uptime)

            if timeRemaining > 0 {
                lastKnownUptime = uptime

                lockoutState = .locked(unlockDate: Date().addingTimeInterval(timeRemaining))
                timer = Timer.scheduledTimer(withTimeInterval: timeRemaining, repeats: false) { [weak self] _ in
                    self?.syncState()
                }
            } else {
                lockoutState = .unlocked(attemptsLeft: 1, maxAttempts: maxAttempts)
            }
        }
    }

    func didUnlock() {
        unlockAttempts = 0
        syncState()
    }

    func didFailUnlock() {
        unlockAttempts += 1

        let uptime = Self.uptime
        unlockUptime = uptime + lockoutInterval
        lastKnownUptime = uptime

        syncState()
    }
}

enum LockoutState {
    case unlocked(attemptsLeft: Int, maxAttempts: Int)
    case locked(unlockDate: Date)

    var isLocked: Bool {
        switch self {
        case .unlocked: return false
        case .locked: return true
        }
    }

    var isAttempted: Bool {
        switch self {
        case let .unlocked(attemptsLeft, maxAttempts): return attemptsLeft != maxAttempts
        case .locked: return true
        }
    }
}

import Foundation
import HsExtensions
import StorageKit

class LockoutManager {
    private let unlockAttemptsKey = "unlock_attempts_keychain_key"
    private let lockTimestampKey = "lock_timestamp_keychain_key"
    private let maxAttempts = 5

    private var secureStorage: ISecureStorage
    private var timer: Timer?

    @PostPublished private(set) var lockoutState: LockoutState = .unlocked(attemptsLeft: 0, maxAttempts: 0)

    private var unlockAttempts: Int {
        didSet {
            try? secureStorage.set(value: unlockAttempts, for: unlockAttemptsKey)
        }
    }

    private var lockTimestamp: TimeInterval {
        didSet {
            try? secureStorage.set(value: lockTimestamp, for: lockTimestampKey)
        }
    }

    init(secureStorage: ISecureStorage) {
        self.secureStorage = secureStorage

        unlockAttempts = secureStorage.value(for: unlockAttemptsKey) ?? 0
        lockTimestamp = secureStorage.value(for: lockTimestampKey) ?? Self.uptime

        syncState()
    }

    private static var uptime: TimeInterval {
        var uptime = timespec()
        clock_gettime(CLOCK_MONOTONIC_RAW, &uptime)
        return TimeInterval(uptime.tv_sec)
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
            let timePast = max(0, Self.uptime - lockTimestamp)
            let lockoutInterval = lockoutInterval

            if timePast > lockoutInterval {
                lockoutState = .unlocked(attemptsLeft: 1, maxAttempts: maxAttempts)
            } else {
                let timeInterval = lockoutInterval - timePast
                lockoutState = .locked(unlockDate: Date().addingTimeInterval(timeInterval))
                timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                    self?.syncState()
                }
            }
        }
    }

    func didUnlock() {
        unlockAttempts = 0
        syncState()
    }

    func didFailUnlock() {
        unlockAttempts += 1
        lockTimestamp = Self.uptime
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

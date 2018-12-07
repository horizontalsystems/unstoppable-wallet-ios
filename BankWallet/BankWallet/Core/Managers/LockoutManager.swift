import Foundation

class LockoutManager: ILockoutManager {
    weak var delegate: ILockoutManagerDelegate? = nil

    private var secureStorage: ISecureStorage
    private var uptimeProvider: IUptimeProvider
    private var timer: IPeriodicTimer
    private var lockoutTimeFrameFactory: ILockoutTimeFrameFactory

    var lockoutThreshold = 5

    init(secureStorage: ISecureStorage, uptimeProvider: IUptimeProvider, delegate: ILockoutManagerDelegate, timer: IPeriodicTimer, lockoutTimeFrameFactory: ILockoutTimeFrameFactory) {
        self.delegate = delegate
        self.secureStorage = secureStorage
        self.uptimeProvider = uptimeProvider
        self.timer = timer
        self.timer.schedule()
        self.lockoutTimeFrameFactory = lockoutTimeFrameFactory

        self.timer.delegate = self
    }

    var isLockedOut: Bool {
        return failedTimes ?? 0 >= lockoutThreshold && lockoutTimeFrame > 0
    }

    var failedTimes: Int? {
        get {
            return secureStorage.unlockAttempts
        }
        set {
            try? secureStorage.set(unlockAttempts: newValue)
            if let newValue = newValue, newValue >= lockoutThreshold {
                delegate?.lockout(timeFrame: lockoutTimeFrame)
            }
            try? secureStorage.set(lockoutTimestamp: newValue == nil ? nil : uptimeProvider.uptime)
        }
    }

    var attemptsLeft: Int {
        get {
            let attemptsLeft = lockoutThreshold - (failedTimes ?? 0)
            return attemptsLeft <= 0 ? 1 : attemptsLeft
        }
    }

    var lockoutTimeFrame: TimeInterval {
        updateStoredUptimeIfNeeded()

        guard let lockoutTimestamp = secureStorage.lockoutTimestamp, let failedTimes = failedTimes else {
            return 0
        }
        return lockoutTimeFrameFactory.lockoutTimeFrame(failedAttempts: failedTimes, lockoutTimestamp: lockoutTimestamp, uptime: uptimeProvider.uptime)
    }

    func updateStoredUptimeIfNeeded() {
        if let lockoutTimestamp = secureStorage.lockoutTimestamp, lockoutTimestamp > uptimeProvider.uptime {
            try? secureStorage.set(lockoutTimestamp: uptimeProvider.uptime)
        }
    }
}

extension LockoutManager: IPeriodicTimerDelegate {

    func onFire() {
        if lockoutTimeFrame == 0 {
            delegate?.finishLockout()
        }
    }

}
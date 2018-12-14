import Foundation

class LockoutManager: ILockoutManager {

    private var secureStorage: ISecureStorage
    private var uptimeProvider: IUptimeProvider
    private var lockoutUntilDateFactory: ILockoutUntilDateFactory

    private let lockoutThreshold = 5

    init(secureStorage: ISecureStorage, uptimeProvider: IUptimeProvider, lockoutTimeFrameFactory: ILockoutUntilDateFactory) {
        self.secureStorage = secureStorage
        self.uptimeProvider = uptimeProvider
        self.lockoutUntilDateFactory = lockoutTimeFrameFactory
    }

    var currentState: LockoutState {
        let uptime = uptimeProvider.uptime
        let unlockAttempts = secureStorage.unlockAttempts ?? 0
        let unlockDate = lockoutUntilDateFactory.lockoutUntilDate(failedAttempts: unlockAttempts, lockoutTimestamp: secureStorage.lockoutTimestamp ?? uptime, uptime: uptime)

        if unlockAttempts >= lockoutThreshold, Date().compare(unlockDate) == .orderedAscending {
            return .locked(till: unlockDate)
        } else {
            let failedAttempts = secureStorage.unlockAttempts
            let attemptsLeft = failedAttempts.map { failedAttempts -> Int in
                let attemptsLeft = lockoutThreshold - failedAttempts
                return attemptsLeft < 1 ? 1 : attemptsLeft
            }
            return .unlocked(attemptsLeft: attemptsLeft)
        }
    }

    func didFailUnlock() {
        let newValue = (secureStorage.unlockAttempts ?? 0) + 1
        try? secureStorage.set(unlockAttempts: newValue)

        if newValue >= lockoutThreshold {
            try? secureStorage.set(lockoutTimestamp: uptimeProvider.uptime)
        }
    }

    func dropFailedAttempts() {
        try? secureStorage.set(unlockAttempts: nil)
    }

}

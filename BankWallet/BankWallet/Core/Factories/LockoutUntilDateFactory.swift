import Foundation

class LockoutUntilDateFactory: ILockoutUntilDateFactory {
    private let currentDateProvider: ICurrentDateProvider

    init(currentDateProvider: ICurrentDateProvider) {
        self.currentDateProvider = currentDateProvider
    }

    func lockoutUntilDate(failedAttempts: Int, lockoutTimestamp: TimeInterval, uptime: TimeInterval) -> Date {
        var timeFrame: TimeInterval = 0
        if failedAttempts == 5 {
            timeFrame = 60 * 5 - (uptime - lockoutTimestamp)
        }
        if failedAttempts == 6 {
            timeFrame = 60 * 10 - (uptime - lockoutTimestamp)
        }
        if failedAttempts == 7 {
            timeFrame = 60 * 15 - (uptime - lockoutTimestamp)
        }
        if failedAttempts >= 8 {
            timeFrame = 60 * 30 - (uptime - lockoutTimestamp)
        }
        return currentDateProvider.currentDate.addingTimeInterval(timeFrame < 0 ? 0 : timeFrame)
    }

}

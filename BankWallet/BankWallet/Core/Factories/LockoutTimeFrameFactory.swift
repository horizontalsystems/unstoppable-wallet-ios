import Foundation

class LockoutTimeFrameFactory: ILockoutTimeFrameFactory {

    func lockoutTimeFrame(failedAttempts: Int, lockoutTimestamp: TimeInterval, uptime: TimeInterval) -> TimeInterval {
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
        return timeFrame < 0 ? 0 : timeFrame
    }

}

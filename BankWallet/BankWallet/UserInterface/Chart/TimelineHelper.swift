import Foundation

enum GridIntervalType {
    case hour(Int)
    case day(Int)
    case month(Int)
}

class TimelineHelper {

    // return timestamps in minutes for grid vertical lines
    func timestamps(frame: ChartFrame, gridIntervalType: GridIntervalType) -> [TimeInterval] {
        var timestamps = [TimeInterval]()

        let lastDate = Date(timeIntervalSince1970: frame.right)
        var lastTimestamp: TimeInterval
        switch gridIntervalType {
        case .hour:
            lastTimestamp = lastDate.startOfHour?.timeIntervalSince1970 ?? frame.right
        case .day:
            lastTimestamp = lastDate.startOfDay.timeIntervalSince1970
        case .month:
            lastTimestamp = lastDate.startOfMonth?.timeIntervalSince1970 ?? frame.right
        }

        while lastTimestamp >= frame.left {
            timestamps.append(lastTimestamp)
            lastTimestamp = stepBack(for: lastTimestamp, intervalType: gridIntervalType)
        }

        return timestamps
    }

    private func stepBack(for timestamp: TimeInterval, intervalType: GridIntervalType) -> TimeInterval {
        let hourInSeconds: TimeInterval = 60 * 60
        switch intervalType {
        case .hour(let count): return timestamp - TimeInterval(count) * hourInSeconds
        case .day(let count): return timestamp - TimeInterval(count) * 24 * hourInSeconds
        case .month(let count):
            let date = Date(timeIntervalSince1970: timestamp)
            let ago = date.startOfMonth(ago: count)
            return ago?.timeIntervalSince1970 ?? timestamp
        }
    }

}

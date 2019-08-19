import Foundation

extension ChartType {

    var step: TimeInterval {
        switch self {
        case .day: return 6         // 6 hours
        case .week: return 2        // 2 days
        case .month: return 6       // 6 days
        case .halfYear: return 1    // 1 month
        case .year: return 2        // 2 month
        }
    }

}

class TimelineHelper {

    // return timestamps in minutes for grid vertical lines
    func timestamps(frame: ChartFrame, type: ChartType) -> [TimeInterval] {
        var timestamps = [TimeInterval]()

        let lastDate = Date(timeIntervalSince1970: frame.right)
        var lastTimestamp: TimeInterval
        switch type {
        case .day: lastTimestamp = lastDate.startOfHour.timeIntervalSince1970
        case .week, .month: lastTimestamp = lastDate.startOfDay.timeIntervalSince1970
        case .halfYear, .year: lastTimestamp = lastDate.startOfMonth.timeIntervalSince1970
        }

        while lastTimestamp >= frame.left {
            timestamps.append(lastTimestamp)
            lastTimestamp = stepBack(for: lastTimestamp, type: type)
        }

        return timestamps
    }

    private func stepBack(for timestamp: TimeInterval, type: ChartType) -> TimeInterval {
        let hourInSeconds: TimeInterval = 60 * 60
        switch type {
        case .day: return timestamp - type.step * hourInSeconds
        case .week, .month: return timestamp - type.step * 24 * hourInSeconds
        case .halfYear, .year:
            let date = Date(timeIntervalSince1970: timestamp)
            let ago = date.startOfMonth(ago: Int(type.step))
            return ago.timeIntervalSince1970
        }
    }

}

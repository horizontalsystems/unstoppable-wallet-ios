import Foundation

class TimestampFormatter {

    static public func text(timestamp: TimeInterval, type: ChartTypeOld) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: date)

        switch type {
        case .day:
            guard let hour = components.hour else {
                return "--"
            }
            return String("\(hour)")
        case .week:
            return DateHelper.instance.formatDayOfWeek(from: date)
        case .month:
            guard let day = components.day else {
                return "--"
            }
            return String("\(day)")
        case .halfYear, .year:
            return DateHelper.instance.formatMonthOfYear(from: date)
        }
    }

}

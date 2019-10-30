import Foundation

class TimestampFormatter {

    static public func text(timestamp: TimeInterval, gridIntervalType: GridIntervalType) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: date)

        switch gridIntervalType {
        case .hour:
            guard let hour = components.hour else {
                return "--"
            }
            return String("\(hour)")
        case .day(let count):
            if count <= 3 {               // half week for show minimum 2 values
                return DateHelper.instance.formatDayOfWeek(from: date)
            } else {
                guard let day = components.day else {
                    return "--"
                }
                return String("\(day)")
            }
        case .month:
            return DateHelper.instance.formatMonthOfYear(from: date)
        }
    }

}

import UIKit

public extension Date {
    func hoursAfterDate(_ aDate: Date) -> Double {
        let ti = timeIntervalSince(aDate)
        return ti / (60 * 60)
    }

    func minutesAfterDate(_ aDate: Date) -> Double {
        let ti = timeIntervalSince(aDate)
        return ti / 60
    }

    func daysAfterDate(_ aDate: Date) -> Double {
        let ti = timeIntervalSince(aDate)
        return ti / (60 * 60 * 24)
    }

    func isDateInCurrentYear(date: Date) -> Bool {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        return year == calendar.component(.year, from: Date())
    }

    internal func isSameDay(as date: Date) -> Bool {
        Calendar.current.compare(self, to: date, toGranularity: .day) == .orderedSame
    }
}

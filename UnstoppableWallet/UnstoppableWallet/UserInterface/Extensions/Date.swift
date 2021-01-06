import UIKit

extension Date {

    public func hoursAfterDate(_ aDate: Date) -> Double {
        let ti = timeIntervalSince(aDate)
        return ti / (60 * 60)
    }

    public func minutesAfterDate(_ aDate: Date) -> Double {
        let ti = timeIntervalSince(aDate)
        return ti / 60
    }

    public func daysAfterDate(_ aDate: Date) -> Double {
        let ti = timeIntervalSince(aDate)
        return ti / (60 * 60 * 24)
    }

    public func isDateInCurrentYear(date: Date) -> Bool {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        return year == calendar.component(.year, from: Date())
    }

    func isSameDay(as date: Date) -> Bool {
        Calendar.current.compare(self, to: date, toGranularity: .day) == .orderedSame
    }

}

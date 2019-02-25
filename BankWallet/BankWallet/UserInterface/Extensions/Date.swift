import UIKit

public enum DateInterval { case future, today, yesterday, inWeek, inYear, more }

extension Date {

    public func hoursAfterDate(_ aDate: Date) -> Double {
        let ti = self.timeIntervalSince(aDate)
        return ti / (60 * 60)
    }

    public func minutesAfterDate(_ aDate: Date) -> Double {
        let ti = self.timeIntervalSince(aDate)
        return ti / 60
    }

    public func daysAfterDate(_ aDate: Date) -> Double {
        let ti = self.timeIntervalSince(aDate)
        return ti / (60 * 60 * 24)
    }

    public func interval(forDate date: Date) -> DateInterval {
        let days = Date().daysAfterDate(date)
        if days < 0 {
            return .future
        } else if Calendar.current.isDateInToday(date) {
            return .today
        } else if Calendar.current.isDateInYesterday(date) {
            return .yesterday
        } else if days < 6 {
            return .inWeek
        } else if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year) {
            return .inYear
        }
        return .more
    }

    public func isDateInCurrentYear(date: Date) -> Bool {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        return year == calendar.component(.year, from: Date())
    }

    func isSameDay(as date: Date) -> Bool {
        return Calendar.current.compare(self, to: date, toGranularity: .day) == .orderedSame
    }

}

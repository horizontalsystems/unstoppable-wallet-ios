import UIKit
import LanguageKit

class DateHelper {
    static let instance = DateHelper()

    private let planeFormatter = DateFormatter()

    func formatTransactionDate(from date: Date) -> String {
        let correctDate = min(date, Date())
        let isThisYear = Calendar.current.isDate(correctDate, equalTo: Date(), toGranularity: .year)
        let format = isThisYear ? "MMMM d" : "yyyy MMMM d"
        return DateFormatter.cachedFormatter(format: format).string(from: date)
    }

    func formatTransactionTime(from date: Date, useYesterday: Bool = false) -> String {
        DateFormatter.cachedFormatter(format: "\(LanguageHourFormatter.hourFormat):mm").string(from: date)
    }

    func formatRateListTitle(from date: Date) -> String {
        DateFormatter.cachedFormatter(format: "\(LanguageHourFormatter.hourFormat):mm").string(from: date)
    }

    func formatLog(date: Date) -> String {
        DateFormatter.cachedFormatter(format: "HH:mm:ss.SSS").string(from: date)
    }

    func formatTimeOnly(from date: Date) -> String {
        timeOnly().string(from: date)
    }

    func formatFullTime(from date: Date) -> String {
        let formatter = DateFormatter.cachedFormatter(format: "MMM d, yyyy, \(LanguageHourFormatter.hourFormat):mm")
        return formatter.string(from: date)
    }

    func formatFullDateOnly(from date: Date) -> String {
        let formatter = DateFormatter.cachedFormatter(format: "MMM d, yyyy")
        return formatter.string(from: date)
    }

    func formatMonthYear(from date: Date) -> String {
        let formatter = DateFormatter.cachedFormatter(format: "MMMM, yyyy")
        return formatter.string(from: date)
    }

    func formatDayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter.cachedFormatter(format: "E")
        return formatter.string(from: date)
    }

    func formatMonthOfYear(from date: Date) -> String {
        let formatter = DateFormatter.cachedFormatter(format: "MMM")
        return formatter.string(from: date)
    }

    func formatLockoutExpirationDate(from date: Date) -> String {
        DateFormatter.cachedFormatter(format: "\(LanguageHourFormatter.hourFormat):mm:ss").string(from: date)
    }

    func formatSyncedThroughDate(from date: Date) -> String {
        DateFormatter.cachedFormatter(format: "yyyy MMM d").string(from: date)
    }

    func parseDateOnly(string: String) -> Date? {
        planeFormatter.dateFormat = "dd/MM/yyyy"
        return planeFormatter.date(from: string)
    }

    func formatDebug(date: Date) -> String {
        DateFormatter.cachedFormatter(format: "MM/dd/yy, HH:mm:ss").string(from: date)
    }

    func formatShortDateOnly(date: Date) -> String {
        dateOnly(forDate: date).string(from: date)
    }

    private func timeOnly() -> DateFormatter {
        DateFormatter.cachedFormatter(format: "\(LanguageHourFormatter.hourFormat):mm")
    }

    private func dateOnly(forDate date: Date, short: Bool = true) -> DateFormatter {
        if date.isDateInCurrentYear(date: date) {
            return DateFormatter.cachedFormatter(format: short ? "d MMM" : "MMMM d")
        }
        return DateFormatter.cachedFormatter(format: short ? "MM/dd/yy" : "MMMM d, yyyy")
    }

}

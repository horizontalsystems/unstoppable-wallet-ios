import UIKit

public class DateHelper {
    static let instance = DateHelper()

    static let hoursForDetermining: Double = 12

    static var formatters = [String: DateFormatter]()

    private static let twelveHoursAllowed: [String] = ["en"]
    private static var systemHourFormat: String = {
        if let dateFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current), dateFormat.firstIndex(of: "a") == nil {
            return "HH"
        }
        return "hh"
    }()
    static var correctedSystemHourFormat: String {
        return DateHelper.twelveHoursAllowed.contains(App.shared.languageManager.currentLanguage) ? DateHelper.systemHourFormat : "HH"
    }

    private func getFormatter(forFormat format: String) -> DateFormatter {
        if let formatter = DateHelper.formatters[format] {
            return formatter
        }

        let formatter = DateFormatter()
        formatter.locale = Locale.appCurrent
        formatter.setLocalizedDateFormatFromTemplate(format)

        DateHelper.formatters[format] = formatter

        return formatter
    }

    private func timeOnly() -> DateFormatter {
        return getFormatter(forFormat: "\(DateHelper.correctedSystemHourFormat):mm")
    }

    private func dateOnly(forDate date: Date, short: Bool = true) -> DateFormatter {
        if date.isDateInCurrentYear(date: date) {
            return getFormatter(forFormat: short ? "d MMM" : "MMMM d")
        }
        return getFormatter(forFormat: short ? "MM/dd/yy" : "MMMM d, yyyy")
    }

    private func dateTimeFormatter(interval: DateInterval, forDate date: Date, shortWeek: Bool = false) -> DateFormatter {
        switch interval {
        case .future, .today: return timeOnly()
        case .yesterday, .inWeek, .inYear: return getFormatter(forFormat: "d MMMM")
        case .more: return getFormatter(forFormat: "MM/dd/yy")
        }
    }

    func formatTransactionDate(from date: Date) -> String {
        let correctDate = min(date, Date())
        let interval = date.interval(forDate: correctDate)
        let format = interval == .more ? "yyyy MMM d" : "MMM d"
        return getFormatter(forFormat: format).string(from: date)
    }

    public func formatTransactionTime(from date: Date, useYesterday: Bool = false) -> String {
        return getFormatter(forFormat: "\(DateHelper.correctedSystemHourFormat):mm").string(from: date)
    }

    public func formatFullTime(from date: Date) -> String {
        let formatter = getFormatter(forFormat: "MMM d, yyyy, \(DateHelper.correctedSystemHourFormat):mm")
        return formatter.string(from: date)
    }

    public func formatFullDateOnly(from date: Date) -> String {
        let formatter = getFormatter(forFormat: "MMM d, yyyy")
        return formatter.string(from: date)
    }

    public func formatDayOfWeek(from date: Date) -> String {
        let formatter = getFormatter(forFormat: "E")
        return formatter.string(from: date)
    }

    public func formatMonthOfYear(from date: Date) -> String {
        let formatter = getFormatter(forFormat: "MMM")
        return formatter.string(from: date)
    }

    func formatLockoutExpirationDate(from date: Date) -> String {
        return getFormatter(forFormat: "\(DateHelper.correctedSystemHourFormat):mm:ss").string(from: date)
    }

    func formatSyncedThroughDate(from date: Date) -> String {
        return getFormatter(forFormat: "yyyy MMM d").string(from: date)
    }

    func formatDebug(date: Date) -> String {
        return getFormatter(forFormat: "yyyy MMM d, HH:mm:ss").string(from: date)
    }

}

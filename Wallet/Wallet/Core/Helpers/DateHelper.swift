import UIKit

public class DateHelper {
    static let instance = DateHelper()

    static let hoursForDetermining: Double = 12

    static var formatters = [String: DateFormatter]()

    private static let twelveHoursAllowed: [String] = ["en"]
    private static var systemHourFormat: String = {
        if let dateFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current), dateFormat.index(of: "a") == nil {
            return "HH"
        }
        return "hh"
    }()
    static var correctedSystemHourFormat: String {
        return DateHelper.twelveHoursAllowed.contains(LocalizationHelper.instance.language) ? DateHelper.systemHourFormat : "HH"
    }

    private func getFormatter(forFormat format: String) -> DateFormatter {
        if let formatter = DateHelper.formatters[format] {
            return formatter
        }

        let formatter = DateFormatter()
        formatter.locale = LocalizationHelper.instance.locale
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
        case .yesterday, .inWeek: return getFormatter(forFormat: shortWeek ? "EEE" : "EEEE")
        case .inYear, .more: return dateOnly(forDate: date)
        }
    }

    public func formatTransactionTime(from date: Date, useYesterday: Bool = false) -> String {
        let correctDate = min(date, Date())
        let interval = date.interval(forDate: correctDate)
        if useYesterday, interval == .yesterday {
            return "transactions.yesterday".localized
        }
        let formatter = dateTimeFormatter(interval: interval, forDate: correctDate, shortWeek: true)
        return formatter.string(from: correctDate)
    }

    public func formatTransactionInfoTime(from date: Date) -> String {
        let formatter = getFormatter(forFormat: "MMM d, yyyy, \(DateHelper.correctedSystemHourFormat):mm")
        return formatter.string(from: date)
    }

}

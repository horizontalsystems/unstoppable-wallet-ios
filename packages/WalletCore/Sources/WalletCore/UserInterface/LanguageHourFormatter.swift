import Foundation

class LanguageHourFormatter {
    private static let shared = LanguageHourFormatter()

    private let twelveHoursAllowed: [String] = ["en"]
    private let amPmEnabled = DateFormatter.amPmEnabled

    private var hourFormat: String {
        twelveHoursAllowed.contains(LanguageManager.shared.currentLanguage) && amPmEnabled ? "hh" : "HH"
    }

    static var hourFormat: String {
        LanguageHourFormatter.shared.hourFormat
    }
}

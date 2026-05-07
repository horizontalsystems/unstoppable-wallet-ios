import Foundation

extension TimeInterval {
    static let themeAnimationDuration: TimeInterval = 0.3

    var approximateHoursOrMinutes: String {
        let seconds = Int(self)
        let hours = seconds / 3600

        if hours > 0 {
            return "send.duration.hours".localized(hours)
        }

        let minutes = seconds / 60
        return "send.duration.minutes".localized(minutes)
    }
}

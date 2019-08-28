import Foundation

extension TimeInterval {

    var approximateHoursOrMinutes: String {
        let seconds = Int(self)
        let hours = seconds / 3600

        if hours > 0 {
            return "send.duration_hours".localized(hours)
        }

        let minutes = seconds / 60
        return "send.duration_minutes".localized(minutes)
    }

}

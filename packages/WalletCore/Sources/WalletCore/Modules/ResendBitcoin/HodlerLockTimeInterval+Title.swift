import Foundation
import Hodler

extension HodlerPlugin.LockTimeInterval {
    static func title(lockTimeInterval: HodlerPlugin.LockTimeInterval?) -> String {
        guard let lockTimeInterval else {
            return "send.hodler_locktime_off".localized
        }

        switch lockTimeInterval {
        case .hour: return "send.hodler_locktime_hour".localized
        case .month: return "send.hodler_locktime_month".localized
        case .halfYear: return "send.hodler_locktime_half_year".localized
        case .year: return "send.hodler_locktime_year".localized
        }
    }
}

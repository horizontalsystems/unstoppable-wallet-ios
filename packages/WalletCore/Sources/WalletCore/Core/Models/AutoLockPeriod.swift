import Foundation

public enum AutoLockPeriod: String, CaseIterable {
    case immediate
    case minute1
    case minute5
    case minute15
    case minute30
    case hour1

    public var title: String {
        "auto_lock.\(rawValue)".localized
    }

    public var period: TimeInterval {
        switch self {
        case .immediate: return 0
        case .minute1: return 60
        case .minute5: return 5 * 60
        case .minute15: return 15 * 60
        case .minute30: return 30 * 60
        case .hour1: return 60 * 60
        }
    }
}

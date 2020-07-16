enum AlertState: Int, CaseIterable {
    case off = 0
    case percent2 = 2
    case percent5 = 5
    case percent10 = 10
}

extension AlertState: CustomStringConvertible {

    public var description: String {
        switch self {
        case .off: return "settings_notifications.alert_off".localized
        case .percent2: return "2%"
        case .percent5: return "5%"
        case .percent10: return "10%"
        }
    }

}

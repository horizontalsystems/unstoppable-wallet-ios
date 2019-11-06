enum FeeRatePriority: Int, CaseIterable {
    case low
    case medium
    case high

    var title: String {
        switch self {
        case .low: return "send.tx_speed_low".localized
        case .medium: return "send.tx_speed_medium".localized
        case .high: return "send.tx_speed_high".localized
        }
    }

}

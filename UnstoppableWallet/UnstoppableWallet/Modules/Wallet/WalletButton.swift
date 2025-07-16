enum WalletButton {
    case send
    case receive
    case address
    case swap
    case chart
    case scan

    var title: String {
        switch self {
        case .send: return "balance.send".localized
        case .receive: return "balance.receive".localized
        case .address: return "balance.address".localized
        case .swap: return "balance.swap".localized
        case .chart: return "balance.chart".localized
        case .scan: return "balance.scan".localized
        }
    }

    var icon: String {
        switch self {
        case .send: return "arrow_medium_2_up_right_24"
        case .receive: return "arrow_medium_2_down_left_24"
        case .address: return "arrow_medium_2_down_left_24"
        case .swap: return "arrow_swap_2_24"
        case .chart: return "chart_2_24"
        case .scan: return "chart_2_24"
        }
    }

    var accent: Bool {
        switch self {
        case .receive: return true
        default: return false
        }
    }
}

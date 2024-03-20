enum TransactionTypeFilter: String {
    case all, incoming, outgoing, swap, approve

    var statTab: StatTab {
        switch self {
        case .all: return .all
        case .incoming: return .incoming
        case .outgoing: return .outgoing
        case .swap: return .swap
        case .approve: return .approve
        }
    }

    static var allCases: [TransactionTypeFilter] {
        AppConfig.swapEnabled ? [all, incoming, outgoing, swap, approve] : [all, incoming, outgoing, approve]
    }
}

enum TransactionTypeFilter: String {
    case all, incoming, outgoing, swap, approve

    static var allCases: [TransactionTypeFilter] {
        [all, incoming, outgoing] + (AppStateManager.instance.swapEnabled ? [swap] : []) + [approve]
    }

    var title: String {
        switch self {
        case .all: return "transactions.filter_all".localized
        default: return "transactions.types.\(rawValue)".localized
        }
    }
}

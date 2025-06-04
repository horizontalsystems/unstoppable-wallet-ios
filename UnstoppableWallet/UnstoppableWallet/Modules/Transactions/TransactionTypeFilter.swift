enum TransactionTypeFilter: String {
    case all, incoming, outgoing, swap, approve

    static var allCases: [TransactionTypeFilter] {
        AppConfig.swapEnabled ? [all, incoming, outgoing, swap, approve] : [all, incoming, outgoing, approve]
    }

    var title: String {
        switch self {
        case .all: return "transactions.filter_all".localized
        default: return "transactions.types.\(rawValue)".localized
        }
    }
}

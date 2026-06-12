enum TransactionTypeFilter: String {
    case all, incoming, outgoing

    static var allCases: [TransactionTypeFilter] {
        [all, incoming, outgoing]
    }

    var title: String {
        switch self {
        case .all: return "transactions.filter_all".localized
        default: return "transactions.types.\(rawValue)".localized
        }
    }
}

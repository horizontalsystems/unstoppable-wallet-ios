enum TransactionTypeFilter: String {
    case all, incoming, outgoing, swap, approve

    static var allCases: [TransactionTypeFilter] {
        AppConfig.swapEnabled ? [all, incoming, outgoing, swap, approve] : [all, incoming, outgoing, approve]
    }
}

enum TransactionDataSortMode: String, CaseIterable {
    case none
    case shuffle
    case bip69

    var title: String {
        switch self {
        case .none: return "default"
        case .shuffle: return "shuffle"
        case .bip69: return "deterministic"
        }
    }

    static var allCases: [TransactionDataSortMode] = [
        .none,
        .shuffle,
        .bip69
    ]

}

enum TransactionDataSortMode: String, CaseIterable {
    case shuffle
    case bip69

    var title: String {
        switch self {
        case .shuffle: return "shuffle"
        case .bip69: return "deterministic"
        }
    }

}

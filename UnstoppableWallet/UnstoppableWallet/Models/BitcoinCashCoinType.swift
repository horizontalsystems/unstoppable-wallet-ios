enum BitcoinCashCoinType: String, CaseIterable {
    case type0
    case type145

    var title: String {
        switch self {
        case .type0: return "Type 0"
        case .type145: return "Type 145"
        }
    }

    var description: String {
        switch self {
        case .type0: return "Old"
        case .type145: return "New"
        }
    }

}

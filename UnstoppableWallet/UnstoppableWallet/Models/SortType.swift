enum SortType: Int, CaseIterable {
    case value
    case name
    case percentGrowth

    var title: String {
        switch self {
        case .value: return "balance.sort.valueHighToLow".localized
        case .name: return "balance.sort.az".localized
        case .percentGrowth: return "balance.sort.24h_change".localized
        }
    }

}

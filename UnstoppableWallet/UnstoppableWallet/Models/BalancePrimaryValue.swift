enum BalancePrimaryValue: String, CaseIterable {
    case coin
    case currency

    var title: String {
        switch self {
        case .coin: return "appearance.balance_value.coin_value".localized
        case .currency: return "appearance.balance_value.fiat_value".localized
        }
    }

    var subtitle: String {
        switch self {
        case .coin: return "appearance.balance_value.fiat_value".localized
        case .currency: return "appearance.balance_value.coin_value".localized
        }
    }

}

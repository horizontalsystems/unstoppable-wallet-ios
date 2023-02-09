enum BitcoinCashCoinType: String, CaseIterable {
    case type0
    case type145

    var title: String {
        "coin_settings.bitcoin_cash_coin_type.title.\(self)".localized
    }

    var description: String {
        "coin_settings.bitcoin_cash_coin_type.description.\(self)".localized
    }

    var order: Int {
        switch self {
        case .type0: return 0
        case .type145: return 1
        }
    }

}

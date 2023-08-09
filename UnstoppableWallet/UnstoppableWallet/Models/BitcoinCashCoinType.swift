import MarketKit

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
        "coin_settings.bitcoin_cash_coin_type.title.\(self)".localized
    }

    var order: Int {
        switch self {
        case .type0: return 0
        case .type145: return 1
        }
    }

}

extension TokenType.AddressType {

    var bitcoinCashCoinType: BitcoinCashCoinType {
        switch self {
        case .type0: return .type0
        case .type145: return .type145
        }
    }

}

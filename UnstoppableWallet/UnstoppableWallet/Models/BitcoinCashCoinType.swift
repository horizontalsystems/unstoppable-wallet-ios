import MarketKit

enum BitcoinCashCoinType: String, CaseIterable {
    static let `default` = type145

    case type0
    case type145

    var title: String {
        switch self {
        case .type0: return "Type 0"
        case .type145: return "Type 145"
        }
    }

    var addressType: TokenType.AddressType {
        switch self {
        case .type0: return .type0
        case .type145: return .type145
        }
    }

    var description: String {
        "coin_settings.bitcoin_cash_coin_type.title.\(self)".localized
    }

    var order: Int {
        switch self {
        case .type145: return 0
        case .type0: return 1
        }
    }

    var recommended: String {
        self == Self.default ? "blockchain_type.recommended".localized : ""
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

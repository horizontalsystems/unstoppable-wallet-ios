import MarketKit

enum BtcBlockchain: String, CaseIterable {
    case bitcoin
    case bitcoinCash
    case litecoin
    case dash

    func supports(coinType: CoinType) -> Bool {
        switch (self, coinType) {
        case (.bitcoin, .bitcoin): return true
        case (.bitcoinCash, .bitcoinCash): return true
        case (.litecoin, .litecoin): return true
        case (.dash, .dash): return true
        default: return false
        }
    }

    var name: String {
        switch self {
        case .bitcoin: return "Bitcoin"
        case .bitcoinCash: return "Bitcoin Cash"
        case .litecoin: return "Litecoin"
        case .dash: return "Dash"
        }
    }

    var icon24: String {
        switch self {
        case .bitcoin: return "bitcoin_24"
        case .bitcoinCash: return "bitcoin_cash_24"
        case .litecoin: return "litecoin_24"
        case .dash: return "dash_24"
        }
    }

}

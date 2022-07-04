import MarketKit

struct ConfiguredToken {
    let token: Token
    let coinSettings: CoinSettings

    init(token: Token, coinSettings: CoinSettings = [:]) {
        self.token = token
        self.coinSettings = coinSettings
    }
}

extension ConfiguredToken: Hashable {

    public static func ==(lhs: ConfiguredToken, rhs: ConfiguredToken) -> Bool {
        lhs.token == rhs.token && lhs.coinSettings == rhs.coinSettings
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(token)
        hasher.combine(coinSettings)
    }

}

extension ConfiguredToken {

    public var badge: String? {
        switch token.blockchain.type {
        case .bitcoin, .litecoin:
            return coinSettings.derivation?.rawValue.uppercased()
        case .bitcoinCash:
            return coinSettings.bitcoinCashCoinType?.rawValue.uppercased()
        default:
            return token.protocolName?.uppercased()
        }
    }

}

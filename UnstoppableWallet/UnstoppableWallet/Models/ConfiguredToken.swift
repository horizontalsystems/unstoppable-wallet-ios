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
    }

}

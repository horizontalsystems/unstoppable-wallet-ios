import MarketKit

struct ConfiguredToken {
    let token: Token
    let coinSettings: CoinSettings

    init(token: Token, coinSettings: CoinSettings = [:]) {
        self.token = token
        self.coinSettings = coinSettings
    }

    var coin: Coin {
        token.coin
    }

    var blockchain: Blockchain {
        token.blockchain
    }

    var blockchainType: BlockchainType {
        token.blockchainType
    }

    var badge: String? {
        token.blockchain.type.badge(coinSettings: coinSettings) ?? token.protocolName?.uppercased()
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

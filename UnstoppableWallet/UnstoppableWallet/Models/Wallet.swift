import MarketKit

struct Wallet {
    let configuredToken: ConfiguredToken
    let account: Account

    init(configuredToken: ConfiguredToken, account: Account) {
        self.configuredToken = configuredToken
        self.account = account
    }

    init(token: Token, account: Account) {
        configuredToken = ConfiguredToken(token: token)
        self.account = account
    }

    var token: Token {
        configuredToken.token
    }

    var coinSettings: CoinSettings {
        configuredToken.coinSettings
    }

    var coin: Coin {
        token.coin
    }

    var decimals: Int {
        token.decimals
    }

    var badge: String? {
        configuredToken.badge
    }

    var transactionSource: TransactionSource {
        TransactionSource(
                blockchainType: token.blockchainType,
                coinSettings: coinSettings,
                bep2Symbol: token.type.bep2Symbol
        )
    }

}

extension Wallet: Hashable {

    public static func ==(lhs: Wallet, rhs: Wallet) -> Bool {
        lhs.configuredToken == rhs.configuredToken && lhs.account == rhs.account
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(configuredToken)
        hasher.combine(account)
    }

}

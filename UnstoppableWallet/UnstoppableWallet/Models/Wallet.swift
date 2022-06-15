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

    var transactionSource: TransactionSource {
        TransactionSource(token: token, account: account, coinSettings: coinSettings)
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

extension Wallet {

    public var badge: String? {
        switch token.blockchain.type {
        case .bitcoin, .litecoin:
            return coinSettings.derivation?.rawValue.uppercased()
        case .bitcoinCash:
            return coinSettings.bitcoinCashCoinType?.rawValue.uppercased()
        default:
            return token.protocolType?.uppercased()
        }
    }

}
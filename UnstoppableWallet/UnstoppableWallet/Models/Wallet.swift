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
        let symbol: String

        switch token.type {
        case .bep2(let value): symbol = value
        default: symbol = ""
        }

        return TransactionSource(blockchain: token.blockchain, account: account, coinSettings: coinSettings, symbol: symbol)
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
            return token.protocolName?.uppercased()
        }
    }

}
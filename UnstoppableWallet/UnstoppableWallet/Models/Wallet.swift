import CoinKit

struct Wallet {
    let configuredCoin: ConfiguredCoin
    let account: Account

    init(configuredCoin: ConfiguredCoin, account: Account) {
        self.configuredCoin = configuredCoin
        self.account = account
    }

    init(coin: Coin, account: Account) {
        configuredCoin = ConfiguredCoin(coin: coin)
        self.account = account
    }

    var coin: Coin {
        configuredCoin.coin
    }

    var transactionSource: TransactionSource {
        let coinSettings = configuredCoin.settings
        let coin = coin

        switch coin.type {
        case .bitcoin:
            return TransactionSource(blockchain: .bitcoin, account: account, coinSettings: coinSettings)
        case .bitcoinCash:
            return TransactionSource(blockchain: .bitcoinCash, account: account, coinSettings: coinSettings)
        case .dash:
            return TransactionSource(blockchain: .dash, account: account, coinSettings: coinSettings)
        case .litecoin:
            return TransactionSource(blockchain: .litecoin, account: account, coinSettings: coinSettings)
        case .zcash:
            return TransactionSource(blockchain: .zcash, account: account, coinSettings: coinSettings)
        case .bep2(let symbol):
            return TransactionSource(blockchain: .bep2(symbol: symbol), account: account, coinSettings: coinSettings)
        case .ethereum:
            return TransactionSource(blockchain: .ethereum, account: account, coinSettings: coinSettings)
        case .binanceSmartChain:
            return TransactionSource(blockchain: .binanceSmartChain, account: account, coinSettings: coinSettings)
        case .erc20:
            return TransactionSource(blockchain: .ethereum, account: account, coinSettings: coinSettings)
        case .bep20:
            return TransactionSource(blockchain: .binanceSmartChain, account: account, coinSettings: coinSettings)
        case .unsupported:
            fatalError("Unsupported coin may not have transactions to show")
        }
    }

}

extension Wallet: Hashable {

    public static func ==(lhs: Wallet, rhs: Wallet) -> Bool {
        lhs.configuredCoin == rhs.configuredCoin && lhs.account == rhs.account
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(configuredCoin)
        hasher.combine(account)
    }

}

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
        let blockchain: TransactionSource.Blockchain

        switch coin.type {
        case .bitcoin:
            blockchain = .bitcoin
        case .bitcoinCash:
            blockchain = .bitcoinCash
        case .dash:
            blockchain = .dash
        case .litecoin:
            blockchain = .litecoin
        case .zcash:
            blockchain = .zcash
        case .bep2(let symbol):
            blockchain = .bep2(symbol: symbol)
        case .ethereum:
            blockchain = .ethereum
        case .binanceSmartChain:
            blockchain = .binanceSmartChain
        case .erc20:
            blockchain = .ethereum
        case .bep20:
            blockchain = .binanceSmartChain
        case .unsupported:
            fatalError("Unsupported coin may not have transactions to show")
        }

        return TransactionSource(blockchain: blockchain, account: account, coinSettings: configuredCoin.settings)
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

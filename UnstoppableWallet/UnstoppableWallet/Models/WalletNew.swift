import MarketKit

struct WalletNew {
    let configuredPlatformCoin: ConfiguredPlatformCoin
    let account: Account

    init(configuredPlatformCoin: ConfiguredPlatformCoin, account: Account) {
        self.configuredPlatformCoin = configuredPlatformCoin
        self.account = account
    }

    init(platformCoin: PlatformCoin, account: Account) {
        configuredPlatformCoin = ConfiguredPlatformCoin(platformCoin: platformCoin)
        self.account = account
    }

    var platformCoin: PlatformCoin {
        configuredPlatformCoin.platformCoin
    }
    
    var coinSettings: CoinSettings {
        configuredPlatformCoin.coinSettings
    }

    var coin: Coin {
        platformCoin.coin
    }

    var platform: Platform {
        platformCoin.platform
    }

    var coinType: CoinType {
        platform.coinType
    }

    var decimal: Int {
        platform.decimal
    }

    var transactionSource: TransactionSource {
        let blockchain: TransactionSource.Blockchain

        switch coinType {
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
        case .sol20, .unsupported:
            fatalError("Unsupported coin may not have transactions to show")
        }

        return TransactionSource(blockchain: blockchain, account: account, coinSettings: coinSettings)
    }

}

extension WalletNew: Hashable {

    public static func ==(lhs: WalletNew, rhs: WalletNew) -> Bool {
        lhs.platformCoin == rhs.platformCoin && lhs.account == rhs.account
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(platformCoin)
        hasher.combine(account)
    }

}

import MarketKit

struct Wallet {
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

    var decimals: Int {
        platform.decimals
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
        case .ethereum, .erc20:
            blockchain = .evm(blockchain: .ethereum)
        case .binanceSmartChain, .bep20:
            blockchain = .evm(blockchain: .binanceSmartChain)
        case .polygon, .mrc20:
            blockchain = .evm(blockchain: .polygon)
        default:
            fatalError("Unsupported coin may not have transactions to show")
        }

        return TransactionSource(blockchain: blockchain, account: account, coinSettings: coinSettings)
    }

}

extension Wallet: Hashable {

    public static func ==(lhs: Wallet, rhs: Wallet) -> Bool {
        lhs.configuredPlatformCoin == rhs.configuredPlatformCoin && lhs.account == rhs.account
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(configuredPlatformCoin)
        hasher.combine(account)
    }

}

extension Wallet {

    public var badge: String? {
        switch coinType {
        case .bitcoin, .litecoin:
            return coinSettings.derivation?.rawValue.uppercased()
        case .bitcoinCash:
            return coinSettings.bitcoinCashCoinType?.rawValue.uppercased()
        default:
            return coinType.blockchainType
        }
    }

}
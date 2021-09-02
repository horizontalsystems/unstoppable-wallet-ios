import MarketKit

extension CoinType {

    var blockchainType: String? {
        switch self {
        case .erc20: return "ERC20"
        case .bep20: return "BEP20"
        case .bep2: return "BEP2"
        default: ()
        }

        return nil
    }

    var platformType: String {
        switch self {
        case .ethereum, .erc20: return "Ethereum"
        case .binanceSmartChain, .bep20: return "Binance Smart Chain"
        case .bep2: return "Binance"
        case .sol20: return "Solana"
        default: return ""
        }
    }

    var platformCoinType: String {
        switch self {
        case .ethereum, .binanceSmartChain: return "Native"
        case .erc20: return "ERC20"
        case .bep20: return "BEP20"
        case .bep2: return "BEP2"
        case .sol20: return "SOL20"
        default: return ""
        }
    }

    var swappable: Bool {
        switch self {
        case .ethereum, .erc20, .binanceSmartChain, .bep20: return true
        default: return false
        }
    }

    var restoreUrl: String {
        switch self {
        case .bitcoin: return "https://btc.horizontalsystems.xyz/apg"
        case .litecoin: return "https://ltc.horizontalsystems.xyz/api"
        case .bitcoinCash: return "https://explorer.bitcoin.com/bch/"
        case .dash: return "https://dash.horizontalsystems.xyz"
        default: return ""
        }
    }

    var title: String {
        switch self {
        case .bitcoin: return "Bitcoin"
        case .litecoin: return "Litecoin"
        case .bitcoinCash: return "Bitcoin Cash"
        default: return ""
        }
    }

    var coinSettingTypes: [CoinSettingType] {
        switch self {
        case .bitcoin, .litecoin: return [.derivation]
        case .bitcoinCash: return [.bitcoinCashCoinType]
        default: return []
        }
    }

    var defaultSettingsArray: [CoinSettings] {
        switch self {
        case .bitcoin, .litecoin: return [[.derivation: MnemonicDerivation.bip49.rawValue]]
        case .bitcoinCash: return [[.bitcoinCashCoinType: BitcoinCashCoinType.type145.rawValue]]
        default: return []
        }
    }

    var restoreSettingTypes: [RestoreSettingType] {
        switch self {
        case .zcash: return [.birthdayHeight]
        default: return []
        }
    }

    var isSupported: Bool {
        switch self {
        case .bitcoin, .litecoin, .bitcoinCash, .dash, .ethereum, .zcash, .binanceSmartChain, .erc20, .bep20, .bep2: return true
        default: return false
        }
    }

}

extension Coin {

    var imageUrl: String {
        let scale = Int(UIScreen.main.scale)
        return "https://markets.nyc3.digitaloceanspaces.com/coin-icons/ios/\(uid)@\(scale)x.png"
    }

}

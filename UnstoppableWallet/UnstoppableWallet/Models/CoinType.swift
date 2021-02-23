import CoinKit

extension CoinType {

    func canSupport(accountType: AccountType) -> Bool {
        switch self {
        case .bitcoin, .litecoin, .bitcoinCash, .dash, .ethereum, .erc20:
            if case let .mnemonic(words, salt) = accountType, words.count == 12, salt == nil { return true }
            return false
        case .binanceSmartChain, .bep20, .bep2:
            if case let .mnemonic(words, salt) = accountType, words.count == 24, salt == nil { return true }
            return false
        case .zcash:
            if case .zcash = accountType { return true }
            return false
        case .unsupported:
            return false
        }
    }

    var predefinedAccountType: PredefinedAccountType {
        switch self {
        case .bitcoin, .litecoin, .bitcoinCash, .dash, .ethereum, .erc20, .unsupported:
            return .standard
        case .binanceSmartChain, .bep20, .bep2:
            return .binance
        case .zcash:
            return .zcash
        }
    }

    var blockchainType: String? {
        switch self {
        case .erc20: return "ERC20"
        case .bep20: return "BEP20"
        case .bep2: return "BEP2"
        default: ()
        }

        return nil
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

}

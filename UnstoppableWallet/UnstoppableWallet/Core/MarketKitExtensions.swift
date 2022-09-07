import UIKit
import MarketKit
import EthereumKit
import NftKit

enum TokenProtocol {
    case native
    case eip20
    case bep2
    case spl
    case unsupported
}

extension MarketKit.Token {

    var protocolName: String? {
        tokenQuery.protocolName
    }

    var isCustom: Bool {
        coin.uid == tokenQuery.customCoinUid
    }

    var isSupported: Bool {
        tokenQuery.isSupported
    }

    var placeholderImageName: String {
        "\(blockchainType.uid)_\(type.tokenProtocol)"
    }

    var swappable: Bool {
        switch blockchainType {
        case .ethereum: return true
        case .binanceSmartChain: return true
        case .polygon: return true
        case .avalanche: return true
        case .optimism: return true
        case .arbitrumOne: return true
        default: return false
        }
    }

    var protocolInfo: String {
        switch type {
        case .native: return blockchain.name
        case .eip20, .bep2: return protocolName ?? ""
        default: return ""
        }
    }

    var typeInfo: String {
        switch type {
        case .native:
            var parts = ["coin_platforms.native".localized]

            switch blockchainType {
            case .binanceSmartChain: parts.append("(BEP20)")
            case .binanceChain: parts.append("(BEP2)")
            default: ()
            }

            return parts.joined(separator: " ")
        case .eip20(let address): return address.shortened
        case .bep2(let symbol): return symbol
        default: return ""
        }
    }

    var copyableTypeInfo: String? {
        switch type {
        case .eip20(let address): return address
        case .bep2(let symbol): return symbol
        default: return nil
        }
    }

}

extension MarketKit.TokenType {

    var tokenProtocol: TokenProtocol {
        switch self {
        case .native: return .native
        case .eip20: return .eip20
        case .bep2: return .bep2
        case .spl: return .spl
        case .unsupported: return .unsupported
        }
    }

    var bep2Symbol: String? {
        switch self {
        case .bep2(let symbol): return symbol
        default: return nil
        }
    }

    var order: Int {
        switch self {
        case .native: return 0
        default: return 1
        }
    }

}

extension MarketKit.TokenQuery {

    var protocolName: String? {
        blockchainType.protocolName(tokenProtocol: tokenType.tokenProtocol)
    }

    var customCoinUid: String {
        "custom-\(id)"
    }

    var isSupported: Bool {
        switch (blockchainType, tokenType) {
        case (.bitcoin, .native): return true
        case (.bitcoinCash, .native): return true
        case (.litecoin, .native): return true
        case (.dash, .native): return true
        case (.zcash, .native): return true
        case (.ethereum, .native), (.ethereum, .eip20): return true
        case (.optimism, .native), (.optimism, .eip20): return true
        case (.arbitrumOne, .native), (.arbitrumOne, .eip20): return true
        case (.binanceSmartChain, .native), (.binanceSmartChain, .eip20): return true
        case (.polygon, .native), (.polygon, .eip20): return true
        case (.avalanche, .native), (.avalanche, .eip20): return true
        case (.binanceChain, .native), (.binanceChain, .bep2): return true
        default: return false
        }
    }

}

extension MarketKit.Blockchain {

    var shortName: String {
        switch type {
        case .binanceSmartChain: return "BSC"
        default: return name
        }
    }

}

extension MarketKit.BlockchainType {

    func protocolName(tokenProtocol: TokenProtocol) -> String? {
        switch tokenProtocol {
        case .native:
            switch self {
            case .optimism: return "Optimism"
            case .arbitrumOne: return "Arbitrum"
            case .binanceChain: return "BEP2"
            default: return nil
            }
        case .eip20:
            switch self {
            case .ethereum: return "ERC20"
            case .binanceSmartChain: return "BEP20"
            case .polygon: return "Polygon"
            case .avalanche: return "Avalanche"
            case .optimism: return "Optimism"
            case .arbitrumOne: return "Arbitrum"
            default: return nil
            }
        case .bep2:
            return "BEP2"
        case .spl:
            return "SPL"
        default:
            return nil
        }
    }

    func placeholderImageName(tokenProtocol: TokenProtocol?) -> String {
        tokenProtocol.map { "\(uid)_\($0)" } ?? "icon_placeholder_24"
    }

    var iconPlain24: String {
        "\(uid)_trx_24"
    }

    var imageUrl: String {
        let scale = Int(UIScreen.main.scale)
        return "https://markets.nyc3.digitaloceanspaces.com/blockchain-icons/\(uid)@\(scale)x.png"
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

    var order: Int {
        switch self {
        case .bitcoin: return 1
        case .ethereum: return 2
        case .binanceSmartChain: return 3
        case .polygon: return 4
        case .avalanche: return 5
        case .zcash: return 6
        case .dash: return 7
        case .bitcoinCash: return 8
        case .litecoin: return 9
        case .binanceChain: return 10
        case .arbitrumOne: return 11
        case .optimism: return 12
        default: return Int.max
        }
    }

    var resendable: Bool {
        switch self {
        case .optimism, .arbitrumOne: return false
        default: return true
        }
    }

    var rollupFeeContractAddress: EthereumKit.Address? {
        switch self {
        case .optimism: return try? EthereumKit.Address(hex: "0x420000000000000000000000000000000000000F")
        default: return nil
        }
    }

    // used for EVM blockchains only
    var feePriceScale: FeePriceScale {
        switch self {
        case .avalanche: return .nAvax
        default: return .gwei
        }
    }

    // used for EVM blockchains only
    var supportedNftTypes: [NftType] {
        switch self {
        case .ethereum: return [.eip721, .eip1155]
//        case .binanceSmartChain: return [.eip721]
//        case .polygon: return [.eip721, .eip1155]
//        case .avalanche: return [.eip721]
//        case .arbitrumOne: return [.eip721]
        default: return []
        }
    }

}

extension MarketKit.Coin {

    var imageUrl: String {
        let scale = Int(UIScreen.main.scale)
        return "https://markets.nyc3.digitaloceanspaces.com/coin-icons/\(uid)@\(scale)x.png"
    }

}

extension MarketKit.TopPlatform {

    var imageUrl: String {
        let scale = Int(UIScreen.main.scale)
        return "https://markets.nyc3.digitaloceanspaces.com/platform-icons/\(blockchain.uid)@\(scale)x.png"
    }

}

extension MarketKit.FullCoin {

    var supportedTokens: [Token] {
        tokens.filter { $0.isSupported }
    }

}

extension MarketKit.CoinCategory {

    var imageUrl: String {
        let scale = Int(UIScreen.main.scale)
        return "https://markets.nyc3.digitaloceanspaces.com/category-icons/\(uid)@\(scale)x.png"
    }

}

extension MarketKit.CoinInvestment.Fund {

    var logoUrl: String {
        let scale = Int(UIScreen.main.scale)
        return "https://markets.nyc3.digitaloceanspaces.com/fund-icons/\(uid)@\(scale)x.png"
    }

}

extension MarketKit.CoinTreasury {

    var fundLogoUrl: String {
        let scale = Int(UIScreen.main.scale)
        return "https://markets.nyc3.digitaloceanspaces.com/treasury-icons/\(fundUid)@\(scale)x.png"
    }

}

extension MarketKit.Auditor {

    var logoUrl: String? {
        let scale = Int(UIScreen.main.scale)
        return "https://markets.nyc3.digitaloceanspaces.com/auditor-icons/\(name)@\(scale)x.png".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }

}

extension Array where Element == FullCoin {

    mutating func sort(filter: String, isEnabled: (Coin) -> Bool) {
        sort { lhsFullCoin, rhsFullCoin in
            let lhsEnabled = isEnabled(lhsFullCoin.coin)
            let rhsEnabled = isEnabled(rhsFullCoin.coin)

            if lhsEnabled != rhsEnabled {
                return lhsEnabled
            }

            if !filter.isEmpty {
                let filter = filter.lowercased()

                let lhsExactCode = lhsFullCoin.coin.code.lowercased() == filter
                let rhsExactCode = rhsFullCoin.coin.code.lowercased() == filter

                if lhsExactCode != rhsExactCode {
                    return lhsExactCode
                }

                let lhsStartsWithCode = lhsFullCoin.coin.code.lowercased().starts(with: filter)
                let rhsStartsWithCode = rhsFullCoin.coin.code.lowercased().starts(with: filter)

                if lhsStartsWithCode != rhsStartsWithCode {
                    return lhsStartsWithCode
                }

                let lhsStartsWithName = lhsFullCoin.coin.name.lowercased().starts(with: filter)
                let rhsStartsWithName = rhsFullCoin.coin.name.lowercased().starts(with: filter)

                if lhsStartsWithName != rhsStartsWithName {
                    return lhsStartsWithName
                }
            }

            let lhsMarketCapRank = lhsFullCoin.coin.marketCapRank ?? Int.max
            let rhsMarketCapRank = rhsFullCoin.coin.marketCapRank ?? Int.max

            if lhsMarketCapRank != rhsMarketCapRank {
                return lhsMarketCapRank < rhsMarketCapRank
            }

            return lhsFullCoin.coin.name.lowercased() < rhsFullCoin.coin.name.lowercased()
        }
    }

}

extension Array where Element == Token {

    var sorted: [Token] {
        sorted {
            let lhsTypeOrder = $0.type.order
            let rhsTypeOrder = $1.type.order

            guard lhsTypeOrder == rhsTypeOrder else {
                return lhsTypeOrder < rhsTypeOrder
            }

            return $0.blockchainType.order < $1.blockchainType.order
        }
    }

}

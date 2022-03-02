import UIKit
import MarketKit

extension MarketKit.CoinType {

    var blockchainType: String? {
        switch self {
        case .erc20: return "ERC20"
        case .bep20: return "BEP20"
        case .polygon, .mrc20: return "POLYGON"
        case .bep2: return "BEP2"
        default: return nil
        }
    }

    var platformType: String {
        switch self {
        case .ethereum: return "Ethereum"
        case .erc20: return "ERC20"
        case .binanceSmartChain: return "Binance Smart Chain"
        case .bep20: return "BEP20"
        case .polygon, .mrc20: return "Polygon"
        case .bep2: return "BEP2"
        default: return ""
        }
    }

    var platformCoinType: String {
        switch self {
        case .ethereum, .binanceSmartChain, .polygon: return "coin_platforms.native".localized
        case .erc20(let address): return address.shortenedAddress
        case .bep20(let address): return address.shortenedAddress
        case .mrc20(let address): return address.shortenedAddress
        case .bep2(let symbol): return symbol
        default: return ""
        }
    }

    var platformIcon: String? {
        switch self {
        case .ethereum, .erc20: return "ethereum_24"
        case .binanceSmartChain, .bep20: return "binance_smart_chain_24"
        case .polygon, .mrc20: return "polygon_24"
        case .bep2: return "binance_chain_24"
        default: return nil
        }
    }

    var swappable: Bool {
        switch self {
        case .ethereum, .erc20, .binanceSmartChain, .bep20, .polygon, .mrc20: return true
        default: return false
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
        case .bitcoin, .litecoin, .bitcoinCash, .dash, .ethereum, .zcash, .binanceSmartChain, .polygon, .erc20, .bep20, .bep2, .mrc20: return true
        default: return false
        }
    }

    var placeholderImageName: String {
        blockchainType.map { "Coin Icon Placeholder - \($0)" } ?? "icon_placeholder_24"
    }

    var order: Int {
        switch self {
        case .bitcoin: return 1
        case .bitcoinCash: return 2
        case .litecoin: return 3
        case .dash: return 4
        case .zcash: return 5
        case .ethereum: return 6
        case .binanceSmartChain: return 7
        case .polygon: return 8
        case .erc20: return 9
        case .bep20: return 10
        case .mrc20: return 11
        case .bep2: return 12
        case .solana: return 13
        case .avalanche: return 14
        case .fantom: return 15
        case .arbitrumOne: return 16
        case .huobiToken: return 17
        case .harmonyShard0: return 18
        case .xdai: return 19
        case .moonriver: return 20
        case .okexChain: return 21
        case .sora: return 22
        case .tomochain: return 23
        case .iotex: return 24
        default: return Int.max
        }
    }

}

extension MarketKit.Coin {

    var isCustom: Bool {
        uid.starts(with: CustomToken.uidPrefix)
    }

    var imageUrl: String {
        let scale = Int(UIScreen.main.scale)
        return "https://markets.nyc3.digitaloceanspaces.com/coin-icons/\(uid)@\(scale)x.png"
    }

}

extension MarketKit.FullCoin {

    var supportedPlatforms: [Platform] {
        platforms.filter { $0.coinType.isSupported }
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

extension Array where Element == CoinType {

    var sorted: [CoinType] {
        sorted { $0.order < $1.order }
    }

}

extension Array where Element == Platform {

    var sorted: [Platform] {
        sorted { $0.coinType.order < $1.coinType.order }
    }

}

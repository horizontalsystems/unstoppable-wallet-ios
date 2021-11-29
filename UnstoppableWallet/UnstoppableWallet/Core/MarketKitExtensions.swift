import UIKit
import MarketKit

extension MarketKit.CoinType {

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
        default: return ""
        }
    }

    var platformCoinType: String {
        switch self {
        case .ethereum, .binanceSmartChain: return "coin_platforms.native".localized
        case .erc20: return "ERC20"
        case .bep20: return "BEP20"
        case .bep2: return "BEP2"
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

    var placeholderImageName: String {
        blockchainType.map { "Coin Icon Placeholder - \($0)" } ?? "icon_placeholder_24"
    }

    var order: Int {
        switch self {
        case .erc20: return 1
        case .bep20: return 2
        case .bep2: return 3
        case .solana: return 4
        case .avalanche: return 5
        case .fantom: return 6
        case .arbitrumOne: return 7
        case .polygonPos: return 8
        case .huobiToken: return 9
        case .harmonyShard0: return 10
        case .xdai: return 11
        case .moonriver: return 12
        case .okexChain: return 13
        case .sora: return 14
        case .tomochain: return 15
        case .iotex: return 16
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

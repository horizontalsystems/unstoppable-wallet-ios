import UIKit
import EvmKit
import NftKit
import MarketKit

extension BlockchainType {

    func placeholderImageName(tokenProtocol: TokenProtocol?) -> String {
        tokenProtocol.map { "\(uid)_\($0)_32" } ?? "placeholder_circle_32"
    }

    var iconPlain32: String {
        "\(uid)_trx_32"
    }

    var imageUrl: String {
        let scale = Int(UIScreen.main.scale)
        return "https://cdn.blocksdecoded.com/blockchain-icons/32px/\(uid)@\(scale)x.png"
    }

    var coinSettingType: CoinSettingType? {
        switch self {
        case .bitcoin, .litecoin: return .derivation
        case .bitcoinCash: return .bitcoinCashCoinType
        default: return nil
        }
    }

    func defaultSettingsArray(accountType: AccountType) -> [CoinSettings] {
        switch self {
        case .bitcoin, .litecoin:
            switch accountType {
            case .mnemonic:
                return [[.derivation: MnemonicDerivation.bip84.rawValue]]
            case .hdExtendedKey(let key):
                return [[.derivation: key.info.purpose.mnemonicDerivation.rawValue]]
            default:
                return []
            }
        case .bitcoinCash:
            return [[.bitcoinCashCoinType: BitcoinCashCoinType.type145.rawValue]]
        default:
            return []
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
        case .bitcoinCash: return 7
        case .litecoin: return 8
        case .dash: return 9
        case .binanceChain: return 10
        case .gnosis: return 11
        case .arbitrumOne: return 12
        case .optimism: return 13
        case .ethereumGoerli: return 14
        default: return Int.max
        }
    }

    var resendable: Bool {
        switch self {
        case .optimism, .arbitrumOne: return false
        default: return true
        }
    }

    var rollupFeeContractAddress: EvmKit.Address? {
        switch self {
        case .optimism: return try? EvmKit.Address(hex: "0x420000000000000000000000000000000000000F")
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
        default: return []
        }
    }

    func supports(accountType: AccountType) -> Bool {
        switch accountType {
        case .mnemonic:
            return true
        case .hdExtendedKey(let key):
            let info = key.info

            switch (self, info.coinType, info.purpose) {
            case (.bitcoin, .bitcoin, .bip44): return true
            case (.bitcoin, .bitcoin, .bip49): return true
            case (.bitcoin, .bitcoin, .bip84): return true
            case (.bitcoinCash, .bitcoin, .bip44): return true
            case (.litecoin, .bitcoin, .bip44): return true
            case (.litecoin, .bitcoin, .bip49): return true
            case (.litecoin, .bitcoin, .bip84): return true
            case (.litecoin, .litecoin, .bip44): return true
            case (.litecoin, .litecoin, .bip49): return true
            case (.dash, .bitcoin, .bip44): return true
            default: return false
            }
        case .evmPrivateKey, .evmAddress:
            switch self {
            case .ethereum, .ethereumGoerli, .binanceSmartChain, .polygon, .avalanche, .optimism, .arbitrumOne, .gnosis: return true
            default: return false
            }
        }
    }

    var isUnsupported: Bool {
        if case .unsupported = self { return true }
        return false
    }

    func badge(coinSettings: CoinSettings) -> String? {
        switch self {
        case .bitcoin, .litecoin:
            return coinSettings.derivation?.rawValue.uppercased()
        case .bitcoinCash:
            return coinSettings.bitcoinCashCoinType?.rawValue.uppercased()
        default:
            return nil
        }
    }

    var description: String {
        switch self {
        case .bitcoin: return "BTC (BIP44, BIP49, BIP84)"
        case .ethereum: return "ETH, ERC20 tokens"
        case .binanceSmartChain: return "BNB, BEP20 tokens"
        case .polygon: return "MATIC, ERC20 tokens"
        case .avalanche: return "AVAX, ERC20 tokens"
        case .gnosis: return "xDAI, ERC20 tokens"
        case .optimism: return "L2 chain"
        case .arbitrumOne: return "L2 chain"
        case .zcash: return "ZEC"
        case .dash: return "DASH"
        case .bitcoinCash: return "BCH (Legacy, CashAddress)"
        case .litecoin: return "LTC (BIP44, BIP49, BIP84)"
        case .binanceChain: return "BNB, BEP2 tokens"
        default: return ""
        }
    }

}

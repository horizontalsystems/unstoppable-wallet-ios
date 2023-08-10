import UIKit
import EvmKit
import NftKit
import MarketKit

extension BlockchainType {
    static let supported: [BlockchainType] = [
        .bitcoin,
        .bitcoinCash,
        .ecash,
        .litecoin,
        .dash,
        .zcash,
        .ethereum,
        .polygon,
        .avalanche,
        .optimism,
        .arbitrumOne,
        .gnosis,
        .fantom,
        .binanceSmartChain,
        .binanceChain,
        .tron
    ]

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
        case .tron: return 4
        case .polygon: return 5
        case .avalanche: return 6
        case .zcash: return 7
        case .bitcoinCash: return 8
        case .ecash: return 9
        case .litecoin: return 10
        case .dash: return 11
        case .binanceChain: return 12
        case .gnosis: return 13
        case .fantom: return 14
        case .arbitrumOne: return 15
        case .optimism: return 16
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

    // todo: remove this method
    func supports(accountType: AccountType) -> Bool {
        switch accountType {
        case .mnemonic:
            return true
        case .hdExtendedKey(let key):
            switch self {
            case .bitcoin: return key.coinTypes.contains(where: { $0 == .bitcoin })
            case .litecoin: return key.coinTypes.contains(where: { $0 == .litecoin })
            case .bitcoinCash, .ecash, .dash: return key.coinTypes.contains(where: { $0 == .bitcoin }) && key.purposes.contains(where: { $0 == .bip44 })
            default: return false
            }
        case .evmPrivateKey, .evmAddress:
            switch self {
            case .ethereum, .binanceSmartChain, .polygon, .avalanche, .optimism, .arbitrumOne, .gnosis, .fantom: return true
            default: return false
            }
        case .tronAddress:
            return self == .tron
        default:
            return false
        }
    }

    var isUnsupported: Bool {
        if case .unsupported = self { return true }
        return false
    }

    var description: String {
        switch self {
        case .bitcoin: return "BTC (BIP44, BIP49, BIP84, BIP86)"
        case .ethereum: return "ETH, ERC20 tokens"
        case .binanceSmartChain: return "BNB, BEP20 tokens"
        case .polygon: return "MATIC, ERC20 tokens"
        case .avalanche: return "AVAX, ERC20 tokens"
        case .gnosis: return "xDAI, ERC20 tokens"
        case .fantom: return "FTM, ERC20 tokens"
        case .optimism: return "L2 chain"
        case .arbitrumOne: return "L2 chain"
        case .zcash: return "ZEC"
        case .dash: return "DASH"
        case .bitcoinCash: return "BCH (Legacy, CashAddress)"
        case .ecash: return "XEC"
        case .litecoin: return "LTC (BIP44, BIP49, BIP84, BIP86)"
        case .binanceChain: return "BNB, BEP2 tokens"
        case .tron: return "TRX, TRC20 tokens"
        default: return ""
        }
    }

    var brandColor: UIColor? {
        switch self {
        case .ethereum: return UIColor(hex: 0x6B7196)
        case .binanceSmartChain: return UIColor(hex: 0xF3BA2F)
        case .polygon: return UIColor(hex: 0x8247E5)
        case .avalanche: return UIColor(hex: 0xD74F49)
        case .optimism: return UIColor(hex: 0xEB3431)
        case .arbitrumOne: return UIColor(hex: 0x96BEDC)
        default: return nil
        }
    }

    var defaultTokenQuery: TokenQuery {
        switch self {
        case .bitcoin, .litecoin:
            return TokenQuery(blockchainType: self, tokenType: .derived(derivation: MnemonicDerivation.default.derivation))
        case .bitcoinCash:
            return TokenQuery(blockchainType: self, tokenType: .addressType(type: BitcoinCashCoinType.default.addressType))
        default:
            return TokenQuery(blockchainType: self, tokenType: .native)
        }
    }

    var nativeTokenQueries: [TokenQuery] {
        switch self {
        case .bitcoin, .litecoin:
            return TokenType.Derivation.allCases.map {
                TokenQuery(blockchainType: self, tokenType: .derived(derivation: $0))
            }
        case .bitcoinCash:
            return TokenType.AddressType.allCases.map {
                TokenQuery(blockchainType: self, tokenType: .addressType(type: $0))
            }
        default:
            return [
                TokenQuery(blockchainType: self, tokenType: .native)
            ]
        }
    }

}

extension BlockchainType: Comparable {

    public static func <(lhs: BlockchainType, rhs: BlockchainType) -> Bool {
        lhs.order < rhs.order
    }

}

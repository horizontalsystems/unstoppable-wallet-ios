import EvmKit
import MarketKit
import NftKit
import SwiftUI
import UIKit

extension BlockchainType {
    static let supported: [BlockchainType] = [
        .bitcoin,
        .bitcoinCash,
        .ecash,
        .litecoin,
        .dash,
        .zcash,
        .monero,
        .zano,
        .ethereum,
        .polygon,
        .avalanche,
        .optimism,
        .arbitrumOne,
        .gnosis,
        .fantom,
        .base,
        .zkSync,
        .robinhood,
        .arc,
        .binanceSmartChain,
        .tron,
        .thorChain,
        .mayaChain,
        .ton,
        .stellar,
        .xrp,
        .solana,
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
        case .zcash, .monero, .zano: return [.birthdayHeight]
        default: return []
        }
    }

    var order: Int {
        let blockchainTypes: [BlockchainType] = [
            .bitcoin,
            .ethereum,
            .monero,
            .zcash,
            .zano,
            .binanceSmartChain,
            .solana,
            .tron,
            .thorChain,
            .mayaChain,
            .base,
            .polygon,
            .arbitrumOne,
            .optimism,
            .stellar,
            .xrp,
            .dash,
            .litecoin,
            .bitcoinCash,
            .avalanche,
            .ton,
            .ecash,
            .zkSync,
            .robinhood,
            .arc,
            .gnosis,
            .fantom,
        ]

        return blockchainTypes.firstIndex(of: self) ?? Int.max
    }

    var resendable: Bool {
        switch self {
        // sequencer-run chains where replacing a pending transaction by nonce does not apply,
        // the same set Android refuses speed-up and cancel on
        case .optimism, .arbitrumOne, .base, .zkSync, .robinhood, .arc: return false
        default: return true
        }
    }

    var rollupFeeContractAddress: EvmKit.Address? {
        switch self {
        case .optimism, .base:
            return try? EvmKit.Address(hex: "0x420000000000000000000000000000000000000F")
        default: return nil
        }
    }

    // used for EVM blockchains only
    var feePriceScale: FeePriceScale {
        switch self {
        case .bitcoin, .bitcoinCash, .dash, .litecoin, .ecash: return .satoshi
        case .avalanche: return .nAvax
        default: return .gwei
        }
    }

    // used for EVM blockchains only
    var supportedNftTypes: [NftType] {
        switch self {
        // case .ethereum: return [.eip721, .eip1155]
        default: return []
        }
    }

    // TODO: remove this method
    func supports(accountType: AccountType) -> Bool {
        switch accountType {
        case .mnemonic:
            return true
        case .passkeyOwned:
            switch self {
            case .ethereum, .binanceSmartChain:
                return true
            default:
                return false
            }
        case let .hdExtendedKey(key):
            switch self {
            case .bitcoin: return key.coinTypes.contains(where: { $0 == .bitcoin })
            case .litecoin: return key.coinTypes.contains(where: { $0 == .litecoin })
            case .bitcoinCash, .ecash, .dash:
                return key.coinTypes.contains(where: { $0 == .bitcoin })
                    && key.purposes.contains(where: { $0 == .bip44 })
            default: return false
            }
        case .evmPrivateKey, .evmAddress:
            switch self {
            case .ethereum, .binanceSmartChain, .polygon, .avalanche, .optimism, .arbitrumOne,
                 .gnosis, .fantom, .base, .zkSync, .robinhood, .arc:
                return true
            default: return false
            }
        case .trcPrivateKey:
            switch self {
            case .tron: return true
            default: return false
            }
        case .stellarSecretKey, .stellarAccount:
            return self == .stellar
        case .tronAddress:
            return self == .tron
        case .tonAddress:
            return self == .ton
        case .solanaAddress:
            return self == .solana
        case .xrpAddress:
            return self == .xrp
        case .thorChainAddress:
            return self == .thorChain
        case .mayaChainAddress:
            return self == .mayaChain
        case let .btcAddress(_, blockchainType, _):
            return self == blockchainType
        case .moneroWatchAccount:
            return self == .monero
        case .moneroMnemonic:
            return self == .monero
        }
    }

    /// A contract that exposes the native coin through an ERC-20 interface over the same balance.
    /// zkSync reports plain ETH movements as transfers of its L2 ETH system contract; Arc predeploys
    /// a 6-decimal view of its 18-decimal native USDC. Neither is a separate token, so neither may
    /// ever become a wallet of its own. Reading such a transfer as the native coin in history is a
    /// separate decision and is made for Arc only, in `EvmTransactionConverter`.
    var nativeTokenContract: (address: String, decimals: Int)? {
        switch self {
        case .zkSync: return ("0x000000000000000000000000000000000000800a", 18)
        case .arc: return ("0x3600000000000000000000000000000000000000", 6)
        default: return nil
        }
    }

    /// Arc mirrors every native movement as a Transfer log from this address. It is not a contract:
    /// the amount is already carried by the transaction value or an internal transaction, so the log
    /// is dropped from history and never treated as a token.
    static let arcNativeTransferLogAddress = "0xfffffffffffffffffffffffffffffffffffffffe"

    /// Addresses whose Transfer logs must never be offered, or accepted, as an ERC-20 wallet.
    var blockedEip20Addresses: Set<String> {
        switch self {
        case .arc: return Set([nativeTokenContract.map(\.address), Self.arcNativeTransferLogAddress].compactMap { $0?.lowercased() })
        default: return Set(nativeTokenContract.map { [$0.address.lowercased()] } ?? [])
        }
    }

    func isBlockedEip20(address: String) -> Bool {
        blockedEip20Addresses.contains(address.lowercased())
    }

    public var isEvm: Bool {
        switch self {
        case .arbitrumOne, .avalanche, .base, .binanceSmartChain, .ethereum, .fantom, .gnosis, .optimism, .polygon, .zkSync, .robinhood, .arc: return true
        default: return false
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
        case .base: return "L2 chain"
        case .zkSync: return "L2 chain"
        case .robinhood: return "L2 chain"
        case .arc: return "USDC, ERC20 tokens"
        case .arbitrumOne: return "L2 chain"
        case .zcash: return "ZEC"
        case .monero: return "XMR"
        case .zano: return "ZANO, confidential assets"
        case .dash: return "DASH"
        case .bitcoinCash: return "BCH (Legacy, CashAddress)"
        case .ecash: return "XEC"
        case .litecoin: return "LTC (BIP44, BIP49, BIP84, BIP86)"
        case .tron: return "TRX, TRC20 tokens"
        case .ton: return "TON"
        case .stellar: return "Stellar"
        case .xrp: return "XRP, XRPL tokens"
        case .thorChain: return "RUNE, THORChain assets"
        case .mayaChain: return "CACAO"
        case .solana: return "SOL, SPL tokens"
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
        case .base: return UIColor(hex: 0x2759F6)
        case .arbitrumOne: return UIColor(hex: 0x96BEDC)
        case .arc: return UIColor(hex: 0x4A7BB7)
        default: return nil
        }
    }

    var brandColorNew: Color? {
        switch self {
        case .ethereum: return Color(hex: 0x6B7196)
        case .binanceSmartChain: return Color(hex: 0xF3BA2F)
        case .polygon: return Color(hex: 0x8247E5)
        case .avalanche: return Color(hex: 0xD74F49)
        case .optimism: return Color(hex: 0xEB3431)
        case .base: return Color(hex: 0x2759F6)
        case .arbitrumOne: return Color(hex: 0x96BEDC)
        case .arc: return Color(hex: 0x4A7BB7)
        default: return nil
        }
    }

    var defaultTokenQuery: TokenQuery {
        switch self {
        case .bitcoin, .litecoin:
            return TokenQuery(
                blockchainType: self,
                tokenType: .derived(derivation: MnemonicDerivation.default.derivation)
            )
        case .bitcoinCash:
            return TokenQuery(
                blockchainType: self,
                tokenType: .addressType(type: BitcoinCashCoinType.default.addressType)
            )
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
                TokenQuery(blockchainType: self, tokenType: .native),
            ]
        }
    }

    func supports(restoreMode: BtcRestoreMode) -> Bool {
        guard case .blockchair = restoreMode else {
            return true
        }

        switch self {
        case .bitcoin, .bitcoinCash, .litecoin: return true
        default: return false
        }
    }

    public var blockTime: TimeInterval? {
        switch self {
        case .ethereum: return 12
        case .tron: return 3
        case .polygon, .avalanche, .optimism, .fantom, .base, .zkSync, .robinhood: return 2
        case .gnosis, .stellar, .ton: return 5
        case .bitcoin, .bitcoinCash, .ecash: return 600
        case .dash, .litecoin: return 150
        case .zcash: return 75
        case .monero: return 120
        case .zano: return 60
        case .binanceSmartChain, .arbitrumOne, .arc: return 1
        case .thorChain, .mayaChain: return nil
        case .xrp: return 4
        case .solana, .unsupported: return nil
        }
    }
}

extension Array where Array.Element == BlockchainType {
    func ordered() -> [BlockchainType] {
        sorted { lhs, rhs in
            lhs.order < rhs.order
        }
    }
}

import MarketKit

extension Token {

    var protocolName: String? {
        switch type {
        case .native:
            switch blockchainType {
                case .ethereum, .binanceSmartChain, .tron: return nil
            case .binanceChain: return "BEP2"
            default: return blockchain.name
            }
        case .eip20:
            switch blockchainType {
            case .ethereum: return "ERC20"
            case .binanceSmartChain: return "BEP20"
            case .tron: return "TRC20"
            default: return blockchain.name
            }
        case .bep2:
            return "BEP2"
        default:
            return blockchain.name
        }
    }

    var tokenBlockchain: String {
        switch type {
        case .native:
            switch blockchainType {
            case .binanceChain: return "\(blockchain.name) (BEP2)"
            default: return blockchain.name
            }
        case .eip20:
            switch blockchainType {
            case .ethereum: return "\(blockchain.name) (ERC20)"
            case .binanceSmartChain: return "\(blockchain.name) (BEP20)"
            case .tron: return "\(blockchain.name) (TRC20)"
            default: return blockchain.name
            }
        case .bep2:
            return "\(blockchain.name) (BEP2)"
        default:
            return blockchain.name
        }
    }

    var isCustom: Bool {
        coin.uid == tokenQuery.customCoinUid
    }

    // todo: remove this method
    var isSupported: Bool {
        tokenQuery.isSupported
    }

    var placeholderImageName: String {
        "\(blockchainType.uid)_\(type.tokenProtocol)_32"
    }

    var swappable: Bool {
        switch blockchainType {
        case .ethereum: return true
        case .binanceSmartChain: return true
        case .polygon: return true
        case .avalanche: return true
        case .optimism: return true
        case .arbitrumOne: return true
        case .gnosis: return true
        case .fantom: return true
        default: return false
        }
    }

    var typeInfo: String {
        switch type {
        case .native: return "coin_platforms.native".localized
        case .derived(let derivation): return derivation.mnemonicDerivation.title
        case .addressType(let type): return type.bitcoinCashCoinType.title
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

    var badge: String? {
        switch type {
        case .derived(let derivation): return derivation.mnemonicDerivation.rawValue.uppercased()
        case .addressType(let type): return type.bitcoinCashCoinType.title.uppercased()
        default: return protocolName?.uppercased()
        }
    }

}

extension Token: Comparable {

    public static func <(lhs: Token, rhs: Token) -> Bool {
        let lhsTypeOrder = lhs.type.order
        let rhsTypeOrder = rhs.type.order

        guard lhsTypeOrder == rhsTypeOrder else {
            return lhsTypeOrder < rhsTypeOrder
        }

        return lhs.blockchainType.order < rhs.blockchainType.order
    }

}

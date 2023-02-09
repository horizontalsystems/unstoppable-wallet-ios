import MarketKit

extension Token {

    var protocolName: String? {
        switch type {
        case .native:
            switch blockchainType {
            case .ethereum, .binanceSmartChain: return nil
            case .binanceChain: return "BEP2"
            default: return blockchain.name
            }
        case .eip20:
            switch blockchainType {
            case .ethereum: return "ERC20"
            case .binanceSmartChain: return "BEP20"
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
        default: return false
        }
    }

    var typeInfo: String {
        switch type {
        case .native: return "coin_platforms.native".localized
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

    func configuredTokens(accountType: AccountType) -> [ConfiguredToken] {
        switch blockchainType {
        case .bitcoin, .litecoin:
            return accountType.supportedDerivations.map {
                ConfiguredToken(token: self, coinSettings: [.derivation: $0.rawValue])
            }
        case .bitcoinCash:
            return BitcoinCashCoinType.allCases.map {
                ConfiguredToken(token: self, coinSettings: [.bitcoinCashCoinType: $0.rawValue])
            }
        default:
            return [ConfiguredToken(token: self)]
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

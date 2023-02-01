import MarketKit

extension Token {

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

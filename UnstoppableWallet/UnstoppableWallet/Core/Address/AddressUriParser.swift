import Foundation
import MarketKit

class AddressUriParser {
    let blockchainType: BlockchainType?
    let tokenType: TokenType?

    init(blockchainType: BlockchainType?, tokenType: TokenType?) {
        self.blockchainType = blockchainType
        self.tokenType = tokenType
    }

    private func pair(_ type: BlockchainType, _ s2: String?) -> String {
        let prefix = type.removeScheme ? nil : type.uriScheme
        return [prefix, s2].compactMap { $0 }.joined(separator: ":")
    }

    private func fullAddress(scheme: String, address: String, uriBlockchainUid: String? = nil) -> String {
        // there is no explicit indication of the blockchain in the uri. We use the rules of the blockchain parser
        guard let uriBlockchainUid else {
            // if has blockchainType check if needed prefix
            if let blockchainType {
                return pair(blockchainType, address)
            }

            // if there is no any blockchainTypes supported, try to determine
            if let type = BlockchainType.supported.first(where: { $0.uriScheme == scheme }) {
                return pair(type, address)
            }
            return address
        }

        // There is a blockchain Uid in the uri. We use it to create an address
        return pair(BlockchainType(uid: uriBlockchainUid), address)
    }

    func parse(addressUri: String) -> Result {
        guard let components = URLComponents(string: addressUri), let scheme = components.scheme else {
            return .noUri
        }
        if let validScheme = blockchainType?.uriScheme, components.scheme != validScheme {
            return .invalidBlockchainType
        }

        var uri = AddressUri(scheme: scheme)
        guard let parameters = components.queryItems else {
            uri.address = fullAddress(scheme: scheme, address: components.path)
            return .uri(uri)
        }

        for parameter in parameters {
            guard let value = parameter.value else { continue }
            if let field = AddressUri.Field(rawValue: parameter.name) {
                uri.parameters[field] = parameter.value
            } else {
                uri.unhandledParameters[parameter.name] = value
            }
        }

        if let uid: String = uri.value(field: .blockchainUid),
           let blockchainType,
           blockchainType != BlockchainType(uid: uid)
        {
            return .invalidBlockchainType
        }

        if let uid: String = uri.value(field: .tokenUid),
           let tokenType,
           tokenType != TokenType(id: uid)
        {
            return .invalidTokenType
        }

        uri.address = fullAddress(scheme: scheme, address: components.path, uriBlockchainUid: uri.parameters[.blockchainUid])
        return .uri(uri)
    }

    static func hasUriPrefix(text: String) -> Bool {
        text.components(separatedBy: ":").count > 1
    }
}

extension AddressUriParser {
    func uri(_ addressUri: AddressUri) -> String {
        var components = URLComponents()
        components.scheme = blockchainType?.uriScheme
        components.path = addressUri.address.stripping(prefix: blockchainType?.uriScheme).stripping(prefix: ":")

        components.queryItems = addressUri.parameters.map {
            URLQueryItem(name: $0.rawValue, value: $1)
        }

        components.queryItems?.append(contentsOf: addressUri.unhandledParameters.map {
            URLQueryItem(name: $0, value: $1)
        })

        if let url = components.url { return url.absoluteString }
        return [components.scheme, components.path].compactMap { $0 }.joined(separator: ":")
    }
}

extension AddressUriParser {
    enum Result {
        case wrongUri
        case invalidBlockchainType
        case invalidTokenType
        case noUri
        case uri(AddressUri)
    }
}

extension BlockchainType {
    var uriScheme: String? {
        if EvmBlockchainManager.blockchainTypes.contains(self) {
            return "ethereum"
        }

        switch self {
        case .bitcoin: return "bitcoin"
        case .bitcoinCash: return "bitcoincash"
        case .ecash: return "ecash"
        case .litecoin: return "litecoin"
        case .dash: return "dash"
        case .zcash: return "zcash"
        case .ethereum: return "ethereum"
        case .binanceChain: return "binancecoin"
        case .tron: return "tron"
        case .ton: return "toncoin"
        default: return nil
        }
    }

    var removeScheme: Bool {
        if EvmBlockchainManager.blockchainTypes.contains(self) {
            return true
        }

        switch self {
        case .bitcoinCash: return false
        case .ecash: return false
        case .bitcoin: return true
        case .litecoin: return true
        case .dash: return true
        case .zcash: return true
        case .ethereum: return true
        case .binanceChain: return true
        case .tron: return true
        case .ton: return true
        default: return false
        }
    }
}

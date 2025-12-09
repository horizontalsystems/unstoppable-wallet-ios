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

    private func parameters(from queryItems: [URLQueryItem]) -> (handled: [AddressUri.Field: String], unhandled: [String: String]) {
        var handled = [AddressUri.Field: String]()
        var unhandled = [String: String]()

        for item in queryItems {
            guard let value = item.value else { continue }
            if let field = AddressUri.Field(rawValue: item.name) {
                handled[field] = value
            } else {
                unhandled[item.name] = value
            }
        }

        return (handled: handled, unhandled: unhandled)
    }

    private func validate(parameters: [AddressUri.Field: String]) throws {
        if let blockchainType,
           let uid: String = parameters[.blockchainUid],
           blockchainType != BlockchainType(uid: uid)
        {
            throw ParseError.invalidBlockchainType
        }

        if let uid: String = parameters[.tokenUid],
           let tokenType,
           tokenType != TokenType(id: uid)
        {
            throw ParseError.invalidTokenType
        }
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

    private func handleDeepLink(url: String) -> AddressUri? {
        guard let components = URLComponents(string: url), let scheme = components.scheme else {
            return nil
        }

        // try to parse ton deeplink
        if scheme == DeepLinkManager.deepLinkScheme, let tonScheme = BlockchainType.ton.uriScheme {
            var uri = AddressUri(scheme: tonScheme)
            uri.address = components.path.stripping(prefix: "/")

            var params = parameters(from: components.queryItems ?? [])
            if let amount = params.handled[.amount] {
                params.handled[.amount] = TonAdapter.amount(kitAmount: amount).description
            }
            params.handled[.blockchainUid] = BlockchainType.ton.uid

            uri.parameters = params.handled
            uri.unhandledParameters = params.unhandled

            return uri
        }

        return nil
    }

    private func handleErc681(scheme: String, path: String) -> (address: String, blockchainType: BlockchainType?) {
//         checking ERC-681. if scheme = "ethereum", address has @chainId. Parse blockchainType from chainId

        let checkErc681 = scheme == BlockchainType.ethereum.uriScheme
        let chunks = checkErc681 ? path.split(separator: "@") : []
        if chunks.count == 2, let chainId = Int(chunks[1]) { // has address and chainId
            let blockchain = Core.shared.evmBlockchainManager.blockchain(chainId: chainId)
            let pureAddress = String(chunks[0])
            return (address: pureAddress, blockchainType: blockchain?.type)
        }

        return (address: path, blockchainType: nil)
    }

    private func handleAddressUri(uri: String, customSchemeHandling: Bool) throws -> AddressUri {
        var replacedUriScheme: String?
        var uriString = uri

        if customSchemeHandling {
            if let (_scheme, remainder) = getNonValidatedCustomScheme(uriString) {
                replacedUriScheme = _scheme
                uriString = "address:\(remainder)"
            } else {
                throw ParseError.noUri
            }
        }

        guard let components = URLComponents(string: uriString), let _scheme = components.scheme else {
            throw ParseError.noUri
        }

        let scheme = replacedUriScheme ?? _scheme
        if let validScheme = blockchainType?.uriScheme, scheme != validScheme {
            throw ParseError.invalidBlockchainType
        }

        var uri = AddressUri(scheme: scheme)
        let (address, blockchainType) = Erc681.support(scheme: scheme) ?
            Erc681.from(path: components.path) :
            (components.path, nil)

        guard let items = components.queryItems else {
            uri.address = fullAddress(scheme: scheme, address: address)
            return uri
        }

        var (handled, unhandled) = parameters(from: items)
        if let blockchainType { // set EVM blockchain type from ERC681 @chainId
            handled[.blockchainUid] = blockchainType.uid
        }
        try validate(parameters: handled)

        uri.parameters = handled
        uri.unhandledParameters = unhandled

        uri.address = fullAddress(scheme: scheme, address: address, uriBlockchainUid: uri.parameters[.blockchainUid])

        return uri
    }

    private func getNonValidatedCustomScheme(_ urlString: String) -> (String, String)? {
        guard let colonIndex = urlString.firstIndex(of: ":") else { return nil }

        return (String(urlString[..<colonIndex]), String(urlString[urlString.index(after: colonIndex)...]))
    }

    static func hasUriPrefix(text: String) -> Bool {
        text.components(separatedBy: ":").count > 1
    }
}

extension AddressUriParser {
    func parse(url: String, customSchemeHandling: Bool = false) throws -> AddressUri {
        // check if we try to parse deeplink address (like ton://transfer/<address>)
        if let addressUri = handleDeepLink(url: url) {
            return addressUri
        }

        return try handleAddressUri(uri: url, customSchemeHandling: customSchemeHandling)
    }

    func uri(_ addressUri: AddressUri) -> String {
        var components = URLComponents()
        components.scheme = blockchainType?.uriScheme
        let pureAddress = addressUri.address.stripping(prefix: blockchainType?.uriScheme).stripping(prefix: ":")

        components.path = Erc681.support(scheme: blockchainType?.uriScheme) ?
            Erc681.to(address: pureAddress, blockchainType: blockchainType) :
            pureAddress

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
    enum ParseError: Error {
        case wrongUri
        case invalidBlockchainType
        case invalidTokenType
        case noUri
    }
}

extension BlockchainType {
    var uriScheme: String? {
        if isEvm {
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
        case .tron: return "tron"
        case .ton: return "toncoin"
        case .monero: return "monero"
        case .stellar: return "stellar"
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
        case .tron: return true
        case .ton: return true
        case .monero: return true
        case .stellar: return true
        default: return false
        }
    }
}

enum Erc681 {
    static func support(scheme: String?) -> Bool {
        scheme != nil && scheme == BlockchainType.ethereum.uriScheme
    }

    static func from(path: String) -> (address: String, blockchainType: BlockchainType?) {
//       checking ERC-681. address has @chainId. Parse blockchainType from chainId

        let chunks = path.split(separator: "@")
        if chunks.count == 2, let chainId = Int(chunks[1]) { // has address and chainId
            let blockchain = Core.shared.evmBlockchainManager.blockchain(chainId: chainId)
            let pureAddress = String(chunks[0])
            return (address: pureAddress, blockchainType: blockchain?.type)
        }

        return (address: path, blockchainType: nil)
    }

    static func to(address: String, blockchainType: BlockchainType?) -> String {
        guard let blockchainType else {
            return address
        }

        guard let chain = try? Core.shared.evmBlockchainManager.chain(blockchainType: blockchainType) else {
            return address
        }

        return [address, chain.id.description].joined(separator: "@")
    }
}

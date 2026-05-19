import Foundation
import MarketKit

class AddressUriParser {
    let blockchainType: BlockchainType?
    let tokenType: TokenType?

    private let bypassParsers: [UriParser]
    private let chain: UriParserChain

    init(blockchainType: BlockchainType?, tokenType: TokenType?) {
        self.blockchainType = blockchainType
        self.tokenType = tokenType
        bypassParsers = [TonTransferDeeplinkParser()]
        chain = UriParserChain(
            parsers: [Erc681Parser(), Bip21Parser()],
            enrichers: [InitFiltersEnricher(blockchainType: blockchainType, tokenType: tokenType)]
        )
    }

    static func hasUriPrefix(text: String) -> Bool {
        text.components(separatedBy: ":").count > 1
    }
}

extension AddressUriParser {
    func parse(url: String, customSchemeHandling: Bool = false) throws -> AddressUri {
        let (scheme, components) = try prelude(url: url, customSchemeHandling: customSchemeHandling)

        // Bypass parsers run before the chain and skip enrichment (master `handleDeepLink` precedence).
        for parser in bypassParsers where parser.canHandle(scheme: scheme, components: components) {
            return try parser.parse(scheme: scheme, components: components)
        }
        return try chain.parse(scheme: scheme, components: components)
    }

    func uri(_ addressUri: AddressUri) -> String {
        var components = URLComponents()
        components.scheme = blockchainType?.uriScheme
        let pureAddress = addressUri.address.stripping(prefix: blockchainType?.uriScheme).stripping(prefix: ":")
        components.path = blockchainType?.uriPath(address: pureAddress) ?? pureAddress

        components.queryItems = addressUri.parameters.map { URLQueryItem(name: $0.rawValue, value: $1) }
        components.queryItems?.append(contentsOf: addressUri.unhandledParameters.map { URLQueryItem(name: $0, value: $1) })

        if let url = components.url { return url.absoluteString }
        return [components.scheme, components.path].compactMap { $0 }.joined(separator: ":")
    }

    private func prelude(url: String, customSchemeHandling: Bool) throws -> (scheme: String, components: URLComponents) {
        var replacedScheme: String?
        var uriString = url

        if customSchemeHandling {
            guard let colonIndex = url.firstIndex(of: ":") else {
                throw ParseError.noUri
            }
            replacedScheme = String(url[..<colonIndex])
            uriString = "address:\(String(url[url.index(after: colonIndex)...]))"
        }

        guard let components = URLComponents(string: uriString), let urlScheme = components.scheme else {
            throw ParseError.noUri
        }
        return (replacedScheme ?? urlScheme, components)
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

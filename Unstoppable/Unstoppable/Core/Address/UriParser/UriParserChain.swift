import Foundation
import MarketKit

protocol UriParser {
    func canHandle(scheme: String, components: URLComponents) -> Bool
    func parse(scheme: String, components: URLComponents) throws -> AddressUri
}

protocol UriEnricher {
    func enrich(_ uri: AddressUri) throws -> AddressUri
}

class UriParserChain {
    private let parsers: [UriParser]
    private let enrichers: [UriEnricher]

    init(parsers: [UriParser], enrichers: [UriEnricher] = []) {
        self.parsers = parsers
        self.enrichers = enrichers
    }

    func parse(scheme: String, components: URLComponents) throws -> AddressUri {
        for parser in parsers where parser.canHandle(scheme: scheme, components: components) {
            var uri = try parser.parse(scheme: scheme, components: components)
            for enricher in enrichers {
                uri = try enricher.enrich(uri)
            }
            return uri
        }
        throw AddressUriParser.ParseError.noUri
    }
}

extension UriParserChain {
    static func parameters(from queryItems: [URLQueryItem]) -> (handled: [AddressUri.Field: String], unhandled: [String: String]) {
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
        return (handled, unhandled)
    }

    static func address(scheme: String, path: String, uriBlockchainUid: String?) -> String {
        if let uid = uriBlockchainUid {
            return pair(BlockchainType(uid: uid), path)
        }
        if let type = BlockchainType.supported.first(where: { $0.uriScheme == scheme }) {
            return pair(type, path)
        }
        return path
    }

    private static func pair(_ type: BlockchainType, _ path: String) -> String {
        let prefix = type.removeScheme ? nil : type.uriScheme
        return [prefix, path].compactMap { $0 }.joined(separator: ":")
    }
}

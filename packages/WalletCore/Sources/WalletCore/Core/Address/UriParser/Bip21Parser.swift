import Foundation
import MarketKit

class Bip21Parser: UriParser {
    func canHandle(scheme _: String, components _: URLComponents) -> Bool {
        true
    }

    func parse(scheme: String, components: URLComponents) throws -> AddressUri {
        let queryItems = components.queryItems ?? []
        let (handled, unhandled) = UriParserChain.parameters(from: queryItems)

        var addressUri = AddressUri(scheme: scheme)
        addressUri.parameters = handled
        addressUri.unhandledParameters = unhandled
        addressUri.address = UriParserChain.address(
            scheme: scheme,
            path: components.path,
            uriBlockchainUid: handled[.blockchainUid]
        )
        return addressUri
    }
}

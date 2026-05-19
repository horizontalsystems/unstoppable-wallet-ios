import Foundation
import MarketKit

// Pre-chain parser invoked by the facade and skipping enrichers — preserves master
// `handleDeepLink` behavior of bypassing init.blockchainType / tokenType filters.
class TonTransferDeeplinkParser: UriParser {
    func canHandle(scheme: String, components: URLComponents) -> Bool {
        scheme == DeepLinkManager.deepLinkScheme && components.host == "transfer"
    }

    func parse(scheme _: String, components: URLComponents) throws -> AddressUri {
        guard let tonScheme = BlockchainType.ton.uriScheme else {
            throw AddressUriParser.ParseError.noUri
        }

        var addressUri = AddressUri(scheme: tonScheme)
        addressUri.address = components.path.stripping(prefix: "/")

        var params = UriParserChain.parameters(from: components.queryItems ?? [])
        if let amount = params.handled[.amount] {
            params.handled[.amount] = TonAdapter.amount(kitAmount: amount).description
        }
        params.handled[.blockchainUid] = BlockchainType.ton.uid

        addressUri.parameters = params.handled
        addressUri.unhandledParameters = params.unhandled
        return addressUri
    }
}

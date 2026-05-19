import Foundation
import MarketKit

class Erc681Parser: UriParser {
    func canHandle(scheme: String, components _: URLComponents) -> Bool {
        scheme == "ethereum"
    }

    func parse(scheme: String, components: URLComponents) throws -> AddressUri {
        let parts = Erc681.from(path: components.path)

        // Reject URIs targeting EVM chains we don't support (e.g. `@130` for Unichain).
        // Silent fall-through would mis-render as a chain-agnostic native EVM URI in the UI.
        if parts.chainId != nil, parts.blockchainType == nil {
            throw AddressUriParser.ParseError.invalidBlockchainType
        }

        let queryItems = components.queryItems ?? []
        var (handled, unhandled) = UriParserChain.parameters(from: queryItems)

        let address: String
        if let transfer = try Erc681PaymentParser.parse(
            parts: parts,
            queryItems: queryItems,
            hasValueParameter: handled[.value] != nil
        ) {
            if let blockchainType = transfer.blockchainType {
                handled[.blockchainUid] = blockchainType.uid
            }
            handled[.tokenUid] = "eip20:\(transfer.contract.lowercased())"
            handled[.value] = transfer.value
            unhandled.removeValue(forKey: "address")
            unhandled.removeValue(forKey: "uint256")
            address = transfer.recipient
        } else {
            if let blockchainType = parts.blockchainType {
                handled[.blockchainUid] = blockchainType.uid
            }
            address = parts.address
        }

        var addressUri = AddressUri(scheme: scheme)
        addressUri.parameters = handled
        addressUri.unhandledParameters = unhandled
        addressUri.address = UriParserChain.address(
            scheme: scheme,
            path: address,
            uriBlockchainUid: handled[.blockchainUid]
        )
        return addressUri
    }
}

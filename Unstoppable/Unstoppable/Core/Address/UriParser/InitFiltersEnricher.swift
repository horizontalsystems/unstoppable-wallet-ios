import Foundation
import MarketKit

struct InitFiltersEnricher: UriEnricher {
    let blockchainType: BlockchainType?
    let tokenType: TokenType?

    func enrich(_ uri: AddressUri) throws -> AddressUri {
        if let blockchainType, let initScheme = blockchainType.uriScheme, initScheme != uri.scheme {
            throw AddressUriParser.ParseError.invalidBlockchainType
        }
        if let blockchainType,
           let uid = uri.parameters[.blockchainUid],
           blockchainType != BlockchainType(uid: uid)
        {
            throw AddressUriParser.ParseError.invalidBlockchainType
        }
        if let tokenType,
           let uid = uri.parameters[.tokenUid],
           tokenType != TokenType(id: uid)
        {
            throw AddressUriParser.ParseError.invalidTokenType
        }
        return uri
    }
}

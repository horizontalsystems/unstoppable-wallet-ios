import Foundation

/// One `GET /v3/tokens/all` row as the swap code needs it: the identifier a request names the asset by
/// and the ids of the providers that list it. `decimals`, `logoURI`, `name`, `ticker`, `coingeckoId` and
/// `shortCode` are decoded from the response but not stored.
public struct USwapCatalogEntry: Codable, Equatable {
    public let identifier: String
    /// Providers with a token list that quote this asset. Not exhaustive: the DEX / LI.FI venues publish
    /// no list and never appear here, and suspensions are not applied (`MultiSwapProviderManager` is).
    public let providerIds: [String]

    public init(identifier: String, providerIds: [String]) {
        self.identifier = identifier
        self.providerIds = providerIds
    }
}

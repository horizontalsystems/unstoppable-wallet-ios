import Foundation
import MarketKit

/// The "can this token be sent privately" rule, kept pure so it is unit-testable: the catalog's provider
/// ids for the token intersected with the synced providers that are private, settle as a plain `transfer`
/// and are not suspended (`MultiSwapProviderManager.privateProviderIds`; the catalog itself does not apply
/// suspensions).
enum USwapPrivateSendGate {
    /// Chains that are already privacy-native: routing them through a confidential intermediary adds
    /// cost without adding unlinkability, so private send is not offered even when a provider lists them.
    static let excludedBlockchainTypes: Set<BlockchainType> = [.monero, .zcash, .zano]

    /// In catalog order.
    static func privateVenueIds(entry: USwapCatalogEntry?, blockchainType: BlockchainType, privateProviderIds: Set<String>) -> [String] {
        guard !excludedBlockchainTypes.contains(blockchainType), let entry else {
            return []
        }

        return entry.providerIds.filter { privateProviderIds.contains($0) }
    }
}

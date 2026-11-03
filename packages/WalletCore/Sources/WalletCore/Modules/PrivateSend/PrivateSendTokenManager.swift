import Combine
import Foundation
import MarketKit

/// Single source of truth for "can this token be sent privately": the catalog's providers for the token
/// intersected with the synced providers that are private, settle as a plain `transfer` and are not
/// suspended (`USwapAssetCatalog.privateVenueIds`). Deliberately separate from the swap screen's view of
/// the same catalog: a token being swappable says nothing about it being privately sendable.
public final class PrivateSendTokenManager {
    private let catalog: USwapAssetCatalog
    private let swapProviderManager: MultiSwapProviderManager

    init(catalog: USwapAssetCatalog, swapProviderManager: MultiSwapProviderManager) {
        self.catalog = catalog
        self.swapProviderManager = swapProviderManager
    }

    public convenience init(catalog: USwapAssetCatalog) {
        self.init(catalog: catalog, swapProviderManager: Core.shared.swapProviderManager)
    }

    /// Fires on a catalog sync and on a provider-list sync: either can reveal or hide the toggle.
    public var syncPublisher: AnyPublisher<Void, Never> {
        catalog.syncPublisher
    }

    /// Pure in-memory lookup over already-synced state. Called from the render path: it must never
    /// trigger a fetch, block, or become async.
    public func supports(token: Token) -> Bool {
        !supportedProviderIds(token: token).isEmpty
    }

    /// The identifier a request names the token by; the same for every provider.
    public func asset(token: Token, providerId _: String) -> String? {
        catalog.asset(token: token)
    }

    public func supportedProviderIds(token: Token) -> [String] {
        catalog.privateVenueIds(token: token)
    }

    public func sync() {
        catalog.sync()
        swapProviderManager.sync()
    }
}

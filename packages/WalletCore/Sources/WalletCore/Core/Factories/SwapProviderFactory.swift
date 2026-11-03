import Foundation
import HsToolKit
import MarketKit

/// Resolves the quote sources. Today there is one, `Core.shared.swapProvider`; the registry stays so a
/// test can swap it for a stub and an app can prepend its own.
public protocol ISwapProviderResolver {
    static var providers: [IMultiSwapProvider] { get }
    /// The provider that tracks a stored swap row. Every row ever saved is tracked by the single USwap
    /// provider, whatever venue id it carries.
    static func provider(trackingProviderId: String) -> IMultiSwapProvider?
}

public class SwapProviderFactory {
    private static var resolvers: [ISwapProviderResolver.Type] = []

    public static func register(_ resolvers: [ISwapProviderResolver.Type]) {
        self.resolvers.append(contentsOf: resolvers)
    }

    public static func prepend(_ resolver: ISwapProviderResolver.Type) {
        resolvers.insert(resolver, at: 0)
    }

    /// Every registered provider, in resolver order, one per id (the first resolver naming an id wins).
    public static var providers: [IMultiSwapProvider] {
        var seen = Set<String>()

        // an explicit closure: a key path over the protocol metatype crashes swift-frontend 6.4 at SIL lowering
        // swiftformat:disable:next preferKeyPath
        return resolvers.flatMap { $0.providers }.filter { seen.insert($0.id).inserted }
    }

    public static func provider(trackingProviderId: String) -> IMultiSwapProvider? {
        for resolver in resolvers {
            if let provider = resolver.provider(trackingProviderId: trackingProviderId) {
                return provider
            }
        }

        return nil
    }

    /// test seam: registry is global mutable state
    static func reset() {
        resolvers = []
    }
}

public enum SwapProviderResolver: ISwapProviderResolver {
    public static var providers: [IMultiSwapProvider] {
        [Core.shared.swapProvider]
    }

    public static func provider(trackingProviderId _: String) -> IMultiSwapProvider? {
        Core.shared.swapProvider
    }

    /// Accessible so the app can build the same USwap API instance for the private send stack
    /// instead of duplicating the base URL / api key construction.
    public static func uSwapApi(networkManager: NetworkManager) -> USwapMultiSwapApi {
        guard let baseURL = URL(string: "\(AppConfig.swapApiUrl)/v3") else {
            preconditionFailure("Invalid USwap API URL: \(AppConfig.swapApiUrl)")
        }

        return USwapMultiSwapApi(
            baseURL: baseURL,
            apiKey: AppConfig.uswapApiKey,
            networkManager: networkManager
        )
    }
}

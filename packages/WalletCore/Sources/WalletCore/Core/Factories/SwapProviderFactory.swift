import Foundation
import HsToolKit

public protocol ISwapProviderResolver {
    static func providerInfo(id: String) -> USwapProviderInfo?
    static func provider(id: String) -> IMultiSwapProvider?
}

public extension ISwapProviderResolver {
    static func providerInfo(id _: String) -> USwapProviderInfo? {
        nil
    }
}

public class SwapProviderFactory {
    private static var resolvers: [ISwapProviderResolver.Type] = []

    public static func register(_ resolvers: [ISwapProviderResolver.Type]) {
        self.resolvers.append(contentsOf: resolvers)
    }

    public static func prepend(_ resolver: ISwapProviderResolver.Type) {
        resolvers.insert(resolver, at: 0)
    }

    public static func provider(id: String) -> IMultiSwapProvider? {
        for resolver in resolvers {
            if let provider = resolver.provider(id: id) {
                return provider
            }
        }

        return nil
    }

    public static func providerInfo(id: String) -> USwapProviderInfo? {
        for resolver in resolvers {
            if let info = resolver.providerInfo(id: id) {
                return info
            }
        }

        return nil
    }

    public static func providerName(id: String) -> String? {
        if let info = providerInfo(id: id) {
            return info.name
        }

        let names: [String: String] = [
            OneInchMultiSwapProvider.id: OneInchMultiSwapProvider.name,
            ThorChainMultiSwapProvider.id: ThorChainMultiSwapProvider.name,
            MayaMultiSwapProvider.id: MayaMultiSwapProvider.name,
            AllBridgeMultiSwapProvider.id: AllBridgeMultiSwapProvider.name,
            UniswapV3MultiSwapProvider.id: UniswapV3MultiSwapProvider.name,
            PancakeV3MultiSwapProvider.id: PancakeV3MultiSwapProvider.name,
            StellarSwapMultiSwapProvider.id: StellarSwapMultiSwapProvider.name,
        ]

        return names[id]
    }

    // test seam: registry is global mutable state
    static func reset() {
        resolvers = []
    }
}

public enum DefaultSwapProviderResolver: ISwapProviderResolver {
    private struct Entry {
        let info: USwapProviderInfo
        let makeProvider: () -> IMultiSwapProvider
    }

    private static let entries: [String: Entry] = Dictionary(
        uniqueKeysWithValues: [
            USwapProviderInfo.near,
            .quickEx,
            .letsExchange,
            .stealthex,
            .swapuz,
            .exolix,
            .cce,
            .barter,
            .pegasus,
            .circle,
            .jupiter,
            .lifi,
        ].map { info in
            (info.id, Entry(info: info, makeProvider: { makeUSwapProvider(info: info) }))
        }
    )

    private static func makeUSwapApi(networkManager: NetworkManager) -> USwapMultiSwapApi {
        guard let baseURL = URL(string: "\(AppConfig.swapApiUrl)/v2") else {
            preconditionFailure("Invalid USwap API URL: \(AppConfig.swapApiUrl)")
        }

        return USwapMultiSwapApi(
            baseURL: baseURL,
            apiKey: AppConfig.uswapApiKey,
            networkManager: networkManager
        )
    }

    private static func makeUSwapProvider(info: USwapProviderInfo) -> IMultiSwapProvider {
        let api = makeUSwapApi(networkManager: NetworkManager(logger: nil))
        return USwapMultiSwapProvider(
            info: info,
            api: api,
            tracker: makeUSwapTracker(api: api)
        )
    }

    private static func makeUSwapTracker(api: USwapMultiSwapApi) -> USwapTracker {
        USwapTracker(
            api: api,
            shouldSimulateFailure: {
                AppConfig.showDevTools && Core.shared.localStorage.simulateFailSwap == .server
            }
        )
    }

    private static func makeUSwapTracker(networkManager: NetworkManager) -> USwapTracker {
        makeUSwapTracker(api: makeUSwapApi(networkManager: networkManager))
    }

    public static func providerInfo(id: String) -> USwapProviderInfo? {
        entries[id]?.info
    }

    public static func provider(id: String) -> IMultiSwapProvider? {
        if id == OneInchMultiSwapProvider.id, let apiKey = AppConfig.oneInchApiKey {
            return OneInchMultiSwapProvider(
                apiKey: apiKey,
                tracker: makeUSwapTracker(networkManager: Core.shared.networkManager)
            )
        }

        if id == ThorChainMultiSwapProvider.id {
            return ThorChainMultiSwapProvider(
                tracker: makeUSwapTracker(networkManager: Core.shared.networkManager)
            )
        }

        if id == MayaMultiSwapProvider.id {
            return MayaMultiSwapProvider(
                tracker: makeUSwapTracker(networkManager: Core.shared.networkManager)
            )
        }

        if id == AllBridgeMultiSwapProvider.id {
            return AllBridgeMultiSwapProvider()
        }

        if id == UniswapV3MultiSwapProvider.id,
           let provider = try? UniswapV3MultiSwapProvider(
               tracker: makeUSwapTracker(networkManager: Core.shared.networkManager)
           )
        {
            return provider
        }

        if id == PancakeV3MultiSwapProvider.id,
           let provider = try? PancakeV3MultiSwapProvider(
               tracker: makeUSwapTracker(networkManager: Core.shared.networkManager)
           )
        {
            return provider
        }

        // Stellar-native swaps are exposed as one provider. The fallback route ids stay
        // internal to StellarSwapMultiSwapProvider and intentionally do not resolve here.
        if id == StellarSwapMultiSwapProvider.id {
            return StellarSwapMultiSwapProvider()
        }

        if let entry = entries[id] {
            return entry.makeProvider()
        }

        return nil
    }
}

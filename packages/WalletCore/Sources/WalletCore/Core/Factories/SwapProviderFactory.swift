public protocol ISwapProviderResolver {
    static func provider(id: String) -> IMultiSwapProvider?
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

    public static func providerName(id: String) -> String? {
        if let provider = USwapProvider(rawValue: id) {
            return provider.title
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
    public static func provider(id: String) -> IMultiSwapProvider? {
        if id == OneInchMultiSwapProvider.id, let apiKey = AppConfig.oneInchApiKey {
            return OneInchMultiSwapProvider(apiKey: apiKey)
        }

        if id == ThorChainMultiSwapProvider.id {
            return ThorChainMultiSwapProvider()
        }

        if id == MayaMultiSwapProvider.id {
            return MayaMultiSwapProvider()
        }

        if id == AllBridgeMultiSwapProvider.id {
            return AllBridgeMultiSwapProvider()
        }

        if id == UniswapV3MultiSwapProvider.id, let provider = try? UniswapV3MultiSwapProvider() {
            return provider
        }

        if id == PancakeV3MultiSwapProvider.id, let provider = try? PancakeV3MultiSwapProvider() {
            return provider
        }

        // Stellar-native swaps: ONE provider card under the server's STELLARBROKER id runs the
        // SB-first waterfall over all four Stellar sources; the fallback ids (SOROSWAP /
        // AQUARIUS / STELLAR_DEX) intentionally resolve to nil so they never appear separately.
        if id == StellarSwapMultiSwapProvider.id {
            return StellarSwapMultiSwapProvider()
        }

        if let provider = USwapProvider(rawValue: id), USwapMultiSwapProvider.supportedProviders.contains(provider) {
            return USwapMultiSwapProvider(provider: provider)
        }

        return nil
    }
}

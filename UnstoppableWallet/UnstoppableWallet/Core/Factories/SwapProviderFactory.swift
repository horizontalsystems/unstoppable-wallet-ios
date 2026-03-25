import OneInchKit

class SwapProviderFactory {
    static func provider(id: String) -> IMultiSwapProvider? {
        if id == OneInchMultiSwapProvider.id, let apiKey = AppConfig.oneInchApiKey {
            return OneInchMultiSwapProvider(kit: OneInchKit.Kit.instance(apiKey: apiKey))
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

        if id == JupiterMultiSwapProvider.id {
            return JupiterMultiSwapProvider()
        }

        if let provider = USwapMultiSwapProvider.Provider(rawValue: id) {
            return USwapMultiSwapProvider(provider: provider)
        }

        return nil
    }

    static func providerName(id: String) -> String? {
        if let provider = USwapMultiSwapProvider.Provider(rawValue: id) {
            return provider.title
        }

        let names: [String: String] = [
            OneInchMultiSwapProvider.id: OneInchMultiSwapProvider.name,
            ThorChainMultiSwapProvider.id: ThorChainMultiSwapProvider.name,
            MayaMultiSwapProvider.id: MayaMultiSwapProvider.name,
            AllBridgeMultiSwapProvider.id: AllBridgeMultiSwapProvider.name,
            JupiterMultiSwapProvider.id: JupiterMultiSwapProvider.name,
        ]

        return names[id]
    }
}

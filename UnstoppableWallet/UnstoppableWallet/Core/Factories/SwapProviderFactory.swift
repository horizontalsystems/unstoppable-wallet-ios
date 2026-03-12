import OneInchKit

class SwapProviderFactory {
    func provider(id: String) -> IMultiSwapProvider? {
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

        if let provider = USwapMultiSwapProvider.Provider(rawValue: id) {
            return USwapMultiSwapProvider(provider: provider)
        }

        return nil
    }
}

import OneInchKit
import UniswapKit

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

        if id == UniswapV3MultiSwapProvider.id, let kit = try? UniswapKit.KitV3.instance(dexType: .uniswap) {
            return UniswapV3MultiSwapProvider(kit: kit)
        }

        if id == PancakeV3MultiSwapProvider.id, let kit = try? UniswapKit.KitV3.instance(dexType: .pancakeSwap) {
            return PancakeV3MultiSwapProvider(kit: kit)
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
            UniswapV3MultiSwapProvider.id: UniswapV3MultiSwapProvider.name,
            PancakeV3MultiSwapProvider.id: PancakeV3MultiSwapProvider.name,
        ]

        return names[id]
    }
}

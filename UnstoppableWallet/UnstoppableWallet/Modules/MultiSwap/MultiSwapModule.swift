import MarketKit
import OneInchKit
import UniswapKit

extension MultiSwapViewModel {
    static func instance(token: MarketKit.Token? = nil) -> MultiSwapViewModel {
        let storage = MultiSwapSettingStorage()
        var providers = [IMultiSwapProvider]()

        // if let kit = try? UniswapKit.Kit.instance() {
        //     providers.append(UniswapV2MultiSwapProvider(kit: kit))
        //     providers.append(PancakeV2MultiSwapProvider(kit: kit))
        //     providers.append(QuickSwapMultiSwapProvider(kit: kit))
        // }

        // if let kit = try? UniswapKit.KitV3.instance(dexType: .uniswap) {
        //     providers.append(UniswapV3MultiSwapProvider(kit: kit))
        // }

        // if let kit = try? UniswapKit.KitV3.instance(dexType: .pancakeSwap) {
        //     providers.append(PancakeV3MultiSwapProvider(kit: kit))
        // }

        if let apiKey = AppConfig.oneInchApiKey {
            providers.append(OneInchMultiSwapProvider(kit: OneInchKit.Kit.instance(apiKey: apiKey)))
        }

        providers.append(ThorChainMultiSwapProvider())
        providers.append(MayaMultiSwapProvider())
        providers.append(AllBridgeMultiSwapProvider())
        providers.append(USwapMultiSwapProvider(provider: .near, apiKey: AppConfig.uswapApiKey))
        providers.append(USwapMultiSwapProvider(provider: .quickEx, apiKey: AppConfig.uswapApiKey))
        providers.append(USwapMultiSwapProvider(provider: .letsExchange, apiKey: AppConfig.uswapApiKey))
        providers.append(USwapMultiSwapProvider(provider: .stealthex, apiKey: AppConfig.uswapApiKey))

        return MultiSwapViewModel(providers: providers, storage: storage, token: token)
    }
}

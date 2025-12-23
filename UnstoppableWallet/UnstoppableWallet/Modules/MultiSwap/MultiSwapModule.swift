import MarketKit
import OneInchKit
import UniswapKit

extension MultiSwapViewModel {
    static func instance(token: MarketKit.Token? = nil) -> MultiSwapViewModel {
        var providers: [IMultiSwapProvider] = [
            ThorChainMultiSwapProvider(),
            MayaMultiSwapProvider(),
            AllBridgeMultiSwapProvider(),
            USwapMultiSwapProvider(provider: .near, apiKey: AppConfig.uswapApiKey),
            USwapMultiSwapProvider(provider: .quickEx, apiKey: AppConfig.uswapApiKey),
            USwapMultiSwapProvider(provider: .letsExchange, apiKey: AppConfig.uswapApiKey),
            USwapMultiSwapProvider(provider: .stealthex, apiKey: AppConfig.uswapApiKey),
        ]

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

        return MultiSwapViewModel(providers: providers, token: token)
    }
}

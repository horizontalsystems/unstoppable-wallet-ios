import EvmKit
import MarketKit
import OneInchKit
import SwiftUI
import UniswapKit

enum MultiSwapModule {
    static func view(token: MarketKit.Token? = nil) -> some View {
        let storage = MultiSwapSettingStorage()
        var providers = [IMultiSwapProvider]()

        if let kit = try? UniswapKit.Kit.instance() {
            providers.append(UniswapV2MultiSwapProvider(kit: kit, storage: storage))
            providers.append(PancakeV2MultiSwapProvider(kit: kit, storage: storage))
            providers.append(QuickSwapMultiSwapProvider(kit: kit, storage: storage))
        }

        if let kit = try? UniswapKit.KitV3.instance(dexType: .uniswap) {
            providers.append(UniswapV3MultiSwapProvider(kit: kit, storage: storage))
        }

        if let kit = try? UniswapKit.KitV3.instance(dexType: .pancakeSwap) {
            providers.append(PancakeV3MultiSwapProvider(kit: kit, storage: storage))
        }

        if let apiKey = AppConfig.oneInchApiKey {
            providers.append(OneInchMultiSwapProvider(kit: OneInchKit.Kit.instance(apiKey: apiKey), storage: storage))
        }

        providers.append(ThorChainMultiSwapProvider(storage: storage))

        let viewModel = MultiSwapViewModel(providers: providers, token: token)
        return MultiSwapView(viewModel: viewModel)
    }
}

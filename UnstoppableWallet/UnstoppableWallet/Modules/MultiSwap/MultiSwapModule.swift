import MarketKit
import OneInchKit
import SwiftUI
import UniswapKit

enum MultiSwapModule {
    static func view(token: MarketKit.Token? = nil) -> some View {
        let storage = MultiSwapSettingStorage()
        var providers = [IMultiSwapProvider]()

        if let kit = try? UniswapKit.Kit.instance() {
            providers.append(UniswapMultiSwapProvider(kit: kit))
            providers.append(PancakeMultiSwapProvider(kit: kit))
        }

        if let kit = try? UniswapKit.KitV3.instance(dexType: .uniswap) {
            providers.append(UniswapV3MultiSwapProvider(kit: kit))
        }

        if let kit = try? UniswapKit.KitV3.instance(dexType: .pancakeSwap) {
            providers.append(PancakeV3MultiSwapProvider(kit: kit))
        }

        if let apiKey = AppConfig.oneInchApiKey, let kit = try? OneInchKit.Kit.instance(apiKey: apiKey) {
            providers.append(OneInchMultiSwapProvider(kit: kit, storage: storage))
        }

        let viewModel = MultiSwapViewModel(providers: providers, token: token)
        return MultiSwapView(viewModel: viewModel)
    }
}

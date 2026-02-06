import Foundation
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
            USwapMultiSwapProvider(provider: .swapuz, apiKey: AppConfig.uswapApiKey),
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

enum PriceImpact {
    static func display(value: Decimal) -> String {
        "-\(abs(value).rounded(decimal: 2).description)%"
    }
}

struct SwapMemo {
    var function: String
    var asset: String
    var destination: String
    var refund: String?
    var params: [String]

    static func parse(_ memo: String) -> SwapMemo? {
        let parts = memo.components(separatedBy: ":")
        guard parts.count >= 3 else { return nil }

        let destinationParts = parts[2].components(separatedBy: "/")

        return SwapMemo(
            function: parts[0],
            asset: parts[1],
            destination: destinationParts[0],
            refund: destinationParts.at(index: 1),
            params: parts.count > 3 ? Array(parts[3...]) : []
        )
    }

    func build() -> String {
        var components = [String]()
        components.append(contentsOf: [function, asset])
        components.append([destination, refund].compactMap { $0 }.joined(separator: "/"))
        components.append(contentsOf: params)

        return components.joined(separator: ":")
    }
}

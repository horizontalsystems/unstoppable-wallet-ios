import MarketKit

class QuickSwapMultiSwapProvider: BaseUniswapV2MultiSwapProvider {
    override var id: String { "quickswap" }
    override var name: String { "QuickSwap" }
    override var type: SwapProviderType { .dex }
    override var icon: String { "swap_provider_quick" }

    override func supports(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token) -> Bool {
        switch (tokenIn.blockchainType, tokenOut.blockchainType) {
        case (.polygon, .polygon): return true
        default: return false
        }
    }
}

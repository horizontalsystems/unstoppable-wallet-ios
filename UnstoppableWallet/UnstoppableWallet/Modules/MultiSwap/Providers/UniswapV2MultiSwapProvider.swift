import MarketKit

class UniswapV2MultiSwapProvider: BaseUniswapV2MultiSwapProvider {
    override var id: String { "uniswap" }
    override var name: String { "Uniswap v.2" }
    override var type: SwapProviderType { .dex }
    override var icon: String { "swap_provider_uniswap" }

    override func supports(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token) -> Bool {
        switch (tokenIn.blockchainType, tokenOut.blockchainType) {
        case (.ethereum, .ethereum): return true
        case (.base, .base): return true
        default: return false
        }
    }
}

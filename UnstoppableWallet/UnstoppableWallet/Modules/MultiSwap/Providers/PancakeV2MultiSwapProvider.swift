import MarketKit

class PancakeV2MultiSwapProvider: BaseUniswapV2MultiSwapProvider {
    override var id: String { "pancake" }
    override var name: String { "PancakeSwap v.2" }
    override var description: String { "DEX" }
    override var icon: String { "swap_provider_pancake" }

    override func supports(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token) -> Bool {
        switch (tokenIn.blockchainType, tokenOut.blockchainType) {
        case (.binanceSmartChain, .binanceSmartChain): return true
        default: return false
        }
    }
}

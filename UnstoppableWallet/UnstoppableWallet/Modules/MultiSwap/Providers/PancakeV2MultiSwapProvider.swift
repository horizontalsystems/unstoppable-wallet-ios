import MarketKit

class PancakeV2MultiSwapProvider: BaseUniswapV2MultiSwapProvider {
    override var id: String {
        "pancake"
    }

    override var name: String {
        "PancakeSwap v.2"
    }

    override var icon: String {
        "pancake_32"
    }

    override func supports(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token) -> Bool {
        switch (tokenIn.blockchainType, tokenOut.blockchainType) {
        case (.binanceSmartChain, .binanceSmartChain): return true
        default: return false
        }
    }
}

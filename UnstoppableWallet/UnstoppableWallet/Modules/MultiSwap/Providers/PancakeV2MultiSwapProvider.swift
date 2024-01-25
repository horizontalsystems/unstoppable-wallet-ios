import MarketKit

class PancakeV2MultiSwapProvider: BaseUniswapV2MultiSwapProvider, IMultiSwapProvider {
    var id: String {
        "pancake"
    }

    var name: String {
        "PancakeSwap v.2"
    }

    var icon: String {
        "pancake_32"
    }

    func supports(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token) -> Bool {
        switch (tokenIn.blockchainType, tokenOut.blockchainType) {
        case (.binanceSmartChain, .binanceSmartChain): return true
        default: return false
        }
    }
}

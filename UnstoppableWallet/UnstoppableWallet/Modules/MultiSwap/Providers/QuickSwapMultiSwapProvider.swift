import MarketKit

class QuickSwapMultiSwapProvider: BaseUniswapV2MultiSwapProvider, IMultiSwapProvider {
    var id: String {
        "quickswap"
    }

    var name: String {
        "QuickSwap"
    }

    var icon: String {
        "quick_32"
    }

    func supports(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token) -> Bool {
        switch (tokenIn.blockchainType, tokenOut.blockchainType) {
        case (.polygon, .polygon): return true
        default: return false
        }
    }
}

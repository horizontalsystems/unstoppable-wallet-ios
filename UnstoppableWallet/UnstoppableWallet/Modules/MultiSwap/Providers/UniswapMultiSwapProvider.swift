import MarketKit

class UniswapMultiSwapProvider: BaseUniswapMultiSwapProvider, IMultiSwapProvider {
    var id: String {
        "uniswap"
    }

    var name: String {
        "Uniswap v.2"
    }

    var icon: String {
        "uniswap_32"
    }

    func supports(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token) -> Bool {
        switch (tokenIn.blockchainType, tokenOut.blockchainType) {
        case (.ethereum, .ethereum): return true
        default: return false
        }
    }
}

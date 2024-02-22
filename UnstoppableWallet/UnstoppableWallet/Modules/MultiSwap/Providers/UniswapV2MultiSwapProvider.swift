import MarketKit

class UniswapV2MultiSwapProvider: BaseUniswapV2MultiSwapProvider {
    override var id: String {
        "uniswap"
    }

    override var name: String {
        "Uniswap v.2"
    }

    override var icon: String {
        "uniswap_32"
    }

    override func supports(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token) -> Bool {
        switch (tokenIn.blockchainType, tokenOut.blockchainType) {
        case (.ethereum, .ethereum): return true
        default: return false
        }
    }
}

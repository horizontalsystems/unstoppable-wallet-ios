import MarketKit

class UniswapV3MultiSwapProvider: BaseUniswapV3MultiSwapProvider, IMultiSwapProvider {
    var id: String {
        "uniswap_v3"
    }

    var name: String {
        "Uniswap v.3"
    }

    var icon: String {
        "uniswap_32"
    }

    func supports(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token) -> Bool {
        guard tokenIn.blockchainType == tokenOut.blockchainType else {
            return false
        }

        switch tokenIn.blockchainType {
        case .ethereum, .binanceSmartChain, .polygon, .arbitrumOne: return true
        default: return false
        }
    }
}

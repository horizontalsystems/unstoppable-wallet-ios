import MarketKit

class PancakeV3MultiSwapProvider: BaseUniswapV3MultiSwapProvider, IMultiSwapProvider {
    var id: String {
        "pancake_v3"
    }

    var name: String {
        "PancakeSwap v.3"
    }

    var icon: String {
        "pancake_32"
    }

    func supports(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token) -> Bool {
        guard tokenIn.blockchainType == tokenOut.blockchainType else {
            return false
        }

        switch tokenIn.blockchainType {
        case .ethereum, .binanceSmartChain: return true
        default: return false
        }
    }
}

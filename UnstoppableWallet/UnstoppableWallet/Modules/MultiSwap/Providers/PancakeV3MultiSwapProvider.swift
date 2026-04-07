import MarketKit

class PancakeV3MultiSwapProvider: BaseUniswapV3MultiSwapProvider {
    static let id = "PANCAKESWAP"
    static let name = "PancakeSwap v.3"
    override var id: String { Self.id }
    override var name: String { Self.name }

    override var type: SwapProviderType { .auto }
    override var icon: String { "swap_provider_pancake" }

    override func supports(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token) -> Bool {
        guard tokenIn.blockchainType == tokenOut.blockchainType else {
            return false
        }

        switch tokenIn.blockchainType {
        case .ethereum, .binanceSmartChain, .zkSync: return true
        default: return false
        }
    }
}

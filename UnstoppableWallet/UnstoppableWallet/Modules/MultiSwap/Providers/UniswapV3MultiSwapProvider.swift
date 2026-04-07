import MarketKit

class UniswapV3MultiSwapProvider: BaseUniswapV3MultiSwapProvider {
    static let id = "UNISWAP_V3"
    static let name = "Uniswap v.3"
    override var id: String { Self.id }
    override var name: String { Self.name }

    override var type: SwapProviderType { .auto }
    override var icon: String { "swap_provider_uniswap" }

    override func supports(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token) -> Bool {
        guard tokenIn.blockchainType == tokenOut.blockchainType else {
            return false
        }

        switch tokenIn.blockchainType {
        case .ethereum, .polygon, .optimism, .arbitrumOne, .binanceSmartChain, .base, .zkSync: return true
        default: return false
        }
    }
}

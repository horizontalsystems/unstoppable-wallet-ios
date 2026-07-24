import MarketKit
import UniswapKit

public class PancakeV3MultiSwapProvider: BaseUniswapV3MultiSwapProvider {
    public static let id = "PANCAKESWAP"
    public static let name = "PancakeSwap v.3"

    public init(tracker: USwapTracker) throws {
        try super.init(kit: UniswapKit.KitV3.instance(dexType: .pancakeSwap), tracker: tracker)
    }

    override public var id: String { Self.id }
    override public var name: String { Self.name }

    override public var type: SwapProviderType { .excellent }
    override public var icon: String { "swap_provider_pancake" }

    override public func supports(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token) -> Bool {
        guard tokenIn.blockchainType == tokenOut.blockchainType else {
            return false
        }

        switch tokenIn.blockchainType {
        case .ethereum, .binanceSmartChain, .zkSync: return true
        default: return false
        }
    }
}

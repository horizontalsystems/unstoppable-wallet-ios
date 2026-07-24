import MarketKit
import UniswapKit

public class UniswapV3MultiSwapProvider: BaseUniswapV3MultiSwapProvider {
    public static let id = "UNISWAP_V3"
    public static let name = "Uniswap v.3"

    public init(tracker: USwapTracker) throws {
        try super.init(kit: UniswapKit.KitV3.instance(dexType: .uniswap), tracker: tracker)
    }

    override public var id: String { Self.id }
    override public var name: String { Self.name }

    override public var type: SwapProviderType { .excellent }
    override public var icon: String { "swap_provider_uniswap" }

    override public func supports(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token) -> Bool {
        guard tokenIn.blockchainType == tokenOut.blockchainType else {
            return false
        }

        switch tokenIn.blockchainType {
        case .ethereum, .polygon, .optimism, .arbitrumOne, .binanceSmartChain, .base, .zkSync: return true
        default: return false
        }
    }
}

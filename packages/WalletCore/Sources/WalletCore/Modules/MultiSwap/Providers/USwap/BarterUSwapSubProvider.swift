import MarketKit

public final class BarterUSwapSubProvider: DefaultUSwapSubProvider {
    private static let nativeAsset = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"

    override public func supports(tokenIn: Token, tokenOut: Token) -> Bool {
        super.supports(tokenIn: tokenIn, tokenOut: tokenOut)
            && tokenIn.blockchainType == tokenOut.blockchainType
    }

    override func asset(token: Token) -> String? {
        guard token.blockchainType.isEvm else {
            return nil
        }

        switch token.type {
        case .native:
            return Self.nativeAsset
        case let .eip20(address):
            return address
        default:
            return nil
        }
    }
}

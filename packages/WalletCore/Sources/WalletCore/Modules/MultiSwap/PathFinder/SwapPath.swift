import MarketKit

/// A two-leg route through one intermediate token, suggested when the pair can't be swapped directly.
public struct SwapPath: Equatable {
    public let tokenIn: Token
    public let intermediateToken: Token
    public let tokenOut: Token
}

import MarketKit

public final class USwapPlainRateQuoteBuilder: USwapRateQuoteBuilder {
    private let supportsToken: (Token) -> Bool

    public init() {
        supportsToken = { token in
            let blockchainType = token.blockchainType

            return !blockchainType.isEvm
                && blockchainType != .tron
                && !blockchainType.isUnsupported
        }
    }

    public init(supportsToken: @escaping (Token) -> Bool) {
        self.supportsToken = supportsToken
    }

    public func supports(tokenIn: Token) -> Bool {
        supportsToken(tokenIn)
    }

    public func build(input: USwapRateQuoteFactory.Input) async throws -> MultiSwapQuote {
        let estimatedTime = input.response.estimatedTime
            ?? MultiSwapHelpers.estimate(tokenIn: input.tokenIn, tokenOut: input.tokenOut)

        return USwapMultiSwapQuote(
            expectedBuyAmount: input.response.expectedBuyAmount,
            estimatedTime: estimatedTime,
            replay: input.replay
        )
    }
}

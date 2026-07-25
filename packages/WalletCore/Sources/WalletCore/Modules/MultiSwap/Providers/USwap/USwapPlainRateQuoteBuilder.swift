import MarketKit

final class USwapPlainRateQuoteBuilder: USwapRateQuoteBuilder {
    func supports(tokenIn: Token) -> Bool {
        let blockchainType = tokenIn.blockchainType

        return !blockchainType.isEvm
            && blockchainType != .tron
            && !blockchainType.isUnsupported
    }

    func build(input: USwapRateQuoteFactory.Input) async throws -> MultiSwapQuote {
        let estimatedTime = input.response.estimatedTime
            ?? MultiSwapHelpers.estimate(tokenIn: input.tokenIn, tokenOut: input.tokenOut)

        return USwapMultiSwapQuote(
            expectedBuyAmount: input.response.expectedBuyAmount,
            estimatedTime: estimatedTime,
            selectedAlternateRoute: input.selectedAlternateRoute
        )
    }
}

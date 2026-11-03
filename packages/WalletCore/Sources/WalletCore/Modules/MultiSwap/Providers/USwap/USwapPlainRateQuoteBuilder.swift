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
        MultiSwapQuote(
            id: input.venue.id,
            venue: input.venue,
            expectedBuyAmount: input.response.expectedBuyAmount,
            estimatedTime: input.estimatedTime,
            zcashAddressRules: input.response.addressRules,
            amlProviderId: input.response.amlProviderId
        )
    }
}

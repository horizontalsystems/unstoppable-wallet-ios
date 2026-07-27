import Foundation
import MarketKit

public protocol USwapFinalQuoteBuilder {
    func supports(input: USwapFinalQuoteFactory.Input) -> Bool
    func build(input: USwapFinalQuoteFactory.Input) async throws -> SwapFinalQuote
}

public final class USwapFinalQuoteFactory {
    public struct Input {
        public let tokenIn: Token
        public let amountIn: Decimal
        public let response: USwapMultiSwapApi.SwapResponse
        public let providerSwapId: String
        public let destinationAddress: String
        public let slippage: Decimal?
        public let recipient: String?
        public let transactionSettings: TransactionSettings?

        public init(
            tokenIn: Token,
            amountIn: Decimal,
            response: USwapMultiSwapApi.SwapResponse,
            providerSwapId: String,
            destinationAddress: String,
            slippage: Decimal?,
            recipient: String?,
            transactionSettings: TransactionSettings?
        ) {
            self.tokenIn = tokenIn
            self.amountIn = amountIn
            self.response = response
            self.providerSwapId = providerSwapId
            self.destinationAddress = destinationAddress
            self.slippage = slippage
            self.recipient = recipient
            self.transactionSettings = transactionSettings
        }
    }

    enum FactoryError: Error {
        case unsupportedBuilder
        case ambiguousBuilders
    }

    private let builders: [USwapFinalQuoteBuilder]

    public init(builders: [USwapFinalQuoteBuilder]) {
        self.builders = builders
    }

    public func build(input: Input) async throws -> SwapFinalQuote {
        let matchingBuilders = builders.filter { $0.supports(input: input) }

        guard matchingBuilders.count == 1 else {
            if matchingBuilders.isEmpty {
                throw FactoryError.unsupportedBuilder
            } else {
                throw FactoryError.ambiguousBuilders
            }
        }

        return try await matchingBuilders[0].build(input: input)
    }
}

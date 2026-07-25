import Foundation
import MarketKit

protocol USwapFinalQuoteBuilder {
    func supports(input: USwapFinalQuoteFactory.Input) -> Bool
    func build(input: USwapFinalQuoteFactory.Input) async throws -> SwapFinalQuote
}

final class USwapFinalQuoteFactory {
    struct Input {
        let tokenIn: Token
        let amountIn: Decimal
        let response: USwapMultiSwapApi.SwapResponse
        let providerSwapId: String
        let destinationAddress: String
        let slippage: Decimal?
        let recipient: String?
        let transactionSettings: TransactionSettings?

        init(
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

    init(builders: [USwapFinalQuoteBuilder]) {
        self.builders = builders
    }

    func build(input: Input) async throws -> SwapFinalQuote {
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

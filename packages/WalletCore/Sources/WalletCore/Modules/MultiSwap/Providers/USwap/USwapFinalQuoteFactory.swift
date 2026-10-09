import Foundation
import MarketKit

public protocol USwapFinalQuoteBuilder {
    func supports(input: USwapFinalQuoteFactory.Input) -> Bool
    func build(input: USwapFinalQuoteFactory.Input) async throws -> SwapFinalQuote
}

public final class USwapFinalQuoteFactory {
    public struct Input {
        // Where a transfer route sends the sell amount: the real deposit (from `execution`) after commit
        // or on a thorchain route, or the preview's stub (`isStub`) that only serves the fee estimate.
        // A stub build is estimate-only: the factory marks the quote `isEstimateOnly`, which withholds
        // its executable until commit rebuilds against the real deposit. A transfer preview without a
        // stub has nothing to estimate against and fails (`noTransactionData`).
        public struct Deposit {
            public let address: String
            public let attachment: USwapMultiSwapApi.Attachment?
            public let isStub: Bool

            public init(address: String, attachment: USwapMultiSwapApi.Attachment?, isStub: Bool) {
                self.address = address
                self.attachment = attachment
                self.isStub = isStub
            }

            init?(instruction: (address: String, attachment: USwapMultiSwapApi.Attachment?)?, isStub: Bool) {
                guard let instruction else {
                    return nil
                }
                self.init(address: instruction.address, attachment: instruction.attachment, isStub: isStub)
            }
        }

        public let tokenIn: Token
        public let amountIn: Decimal
        public let response: USwapMultiSwapApi.SwapResponse
        public let providerSwapId: String?
        public let destinationAddress: String
        public let slippage: Decimal?
        public let recipient: String?
        public let transactionSettings: TransactionSettings?
        // decided by the provider from the route's execution
        public let mevProtectionAllowed: Bool
        // nil on a transfer route without a stub (no fee estimate) and on signed routes
        public let deposit: Deposit?

        public init(
            tokenIn: Token,
            amountIn: Decimal,
            response: USwapMultiSwapApi.SwapResponse,
            providerSwapId: String?,
            destinationAddress: String,
            slippage: Decimal?,
            recipient: String?,
            transactionSettings: TransactionSettings?,
            mevProtectionAllowed: Bool,
            deposit: Deposit?
        ) {
            self.tokenIn = tokenIn
            self.amountIn = amountIn
            self.response = response
            self.providerSwapId = providerSwapId
            self.destinationAddress = destinationAddress
            self.slippage = slippage
            self.recipient = recipient
            self.transactionSettings = transactionSettings
            self.mevProtectionAllowed = mevProtectionAllowed
            self.deposit = deposit
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

        let quote = try await matchingBuilders[0].build(input: input)

        // A stub build serves the fee row only: its payload targets the stand-in address, so the
        // quote refuses to hand out an executable (every chain alike). Commit rebuilds it.
        if input.deposit?.isStub == true {
            quote.isEstimateOnly = true
        }

        return quote
    }
}

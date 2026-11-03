import Combine
import Foundation
import MarketKit
import ObjectMapper
import Testing
@testable import Unstoppable
@testable import WalletCore

/// the "Guaranteed" row must prefer the server-enforced minBuyAmount over the
/// client-side slippage estimate, and the USwap provider must wire it through
struct SwapGuaranteedAmountTests {
    private static func finalQuote(slippage: Decimal?, minAmountOut: Decimal? = nil) -> SwapFinalQuote {
        SwapFinalQuote(
            expectedBuyAmount: 100,
            slippage: slippage,
            recipient: nil,
            transactionError: nil,
            toAddress: "to",
            minAmountOut: minAmountOut
        )
    }

    @Test func guaranteedAmountFallsBackToSlippageEstimate() {
        let quote = Self.finalQuote(slippage: 2)

        #expect(quote.guaranteedAmountOut == 98)
    }

    @Test func guaranteedAmountPrefersServerMinimum() {
        let quote = Self.finalQuote(slippage: 2, minAmountOut: Decimal(string: "97.5"))

        #expect(quote.guaranteedAmountOut == Decimal(string: "97.5"))
    }

    @Test func guaranteedAmountHiddenWithoutSlippage() {
        let quote = Self.finalQuote(slippage: nil, minAmountOut: Decimal(string: "97.5"))

        #expect(quote.guaranteedAmountOut == nil)
    }

    @Test func uswapProviderCarriesServerMinimumIntoFinalQuote() async throws {
        let response = Self.swapResponse(minBuyAmount: Decimal(string: "97.5"))
        let finalQuote = try await Self.confirmationQuote(response: response)

        #expect(finalQuote.minAmountOut == Decimal(string: "97.5"))
        #expect(finalQuote.guaranteedAmountOut == Decimal(string: "97.5"))
    }

    @Test func uswapProviderHidesGuaranteeWhenServerOmitsMinimum() async throws {
        let response = Self.swapResponse(minBuyAmount: nil)
        let finalQuote = try await Self.confirmationQuote(response: response)

        #expect(finalQuote.minAmountOut == nil)
        #expect(finalQuote.guaranteedAmountOut == nil)
    }

    @Test func swapResponseMappingParsesMinBuyAmount() throws {
        let mapping = try USwapMultiSwapApi.SwapResponseMapping(JSONString: """
        {"expectedBuyAmount": "100", "minBuyAmount": "97.5", "uuid": "uuid"}
        """)

        #expect(mapping.response.minBuyAmount == Decimal(string: "97.5"))
    }

    @Test func swapResponseMappingToleratesMissingMinBuyAmount() throws {
        let mapping = try USwapMultiSwapApi.SwapResponseMapping(JSONString: """
        {"expectedBuyAmount": "100", "uuid": "uuid"}
        """)

        #expect(mapping.response.minBuyAmount == nil)
    }
}

extension SwapGuaranteedAmountTests {
    private static func token() -> Token {
        Token(
            coin: Coin(uid: "test-coin", name: "Test", code: "TST"),
            blockchain: Blockchain(type: .ethereum, name: "Test", explorerUrl: nil),
            type: .native,
            decimals: 8
        )
    }

    private static func swapResponse(minBuyAmount: Decimal?) -> USwapMultiSwapApi.SwapResponse {
        USwapMultiSwapApi.SwapResponse(
            expectedBuyAmount: 100,
            minBuyAmount: minBuyAmount,
            buyAsset: nil,
            estimatedTime: nil,
            execution: nil,
            uuid: nil,
            approvalSpender: nil,
            previewToken: "preview-token",
            // a transfer preview without a stub fails outright; the stub only feeds the fee estimate
            stubDepositAddress: "stub-deposit"
        )
    }

    private static func confirmationQuote(response: USwapMultiSwapApi.SwapResponse) async throws -> SwapFinalQuote {
        let request = USwapMultiSwapApi.SwapRequest(
            sellAsset: "ETH.ETH",
            buyAsset: "ETH.USDC",
            sellAmount: 1,
            slippage: 2,
            chainId: "1",
            providerId: "QUICKEX",
            destinationAddress: "destination",
            sourceAddress: nil,
            refundAddress: nil
        )

        return try await USwapMultiSwapProvider.assembleFinalQuote(
            response: response,
            request: request,
            venueId: "QUICKEX",
            tokenIn: token(),
            tokenOut: token(),
            amountIn: 1,
            slippage: 2,
            recipient: nil,
            transactionSettings: nil,
            finalQuoteFactory: USwapFinalQuoteFactory(builders: [StubFinalQuoteBuilder()])
        )
    }

    private struct StubFinalQuoteBuilder: USwapFinalQuoteBuilder {
        func supports(input _: USwapFinalQuoteFactory.Input) -> Bool {
            true
        }

        func build(input: USwapFinalQuoteFactory.Input) async throws -> SwapFinalQuote {
            SwapFinalQuote(
                expectedBuyAmount: input.response.expectedBuyAmount,
                slippage: input.slippage,
                recipient: input.recipient,
                transactionError: nil,
                toAddress: input.destinationAddress,
                providerSwapId: input.providerSwapId
            )
        }
    }
}

import Foundation
import MarketKit
import ObjectMapper
import Testing
@testable import WalletCore

struct ThorChainSwapQuoteTests {
    @Test func nativeQuoteDecodesWithoutAnInboundAddress() throws {
        // A THORChain-native swap has no vault to pay into, so THORNode omits the field.
        // Decoding it strictly would reject exactly the quote the deposit path needs.
        let quote = try BaseThorChainMultiSwapProvider.SwapQuote(JSONString: Self.json(inboundAddress: nil))

        #expect(quote.inboundAddress == nil)
        #expect(quote.memo == "=:BTC.BTC:bc1qexample")
        #expect(quote.expectedAmountOut == Decimal(string: "0.12345678"))
    }

    @Test func quoteFromAnotherChainKeepsItsInboundAddress() throws {
        let quote = try BaseThorChainMultiSwapProvider.SwapQuote(JSONString: Self.json(inboundAddress: "bc1qvault"))

        #expect(quote.inboundAddress == "bc1qvault")
    }

    @Test func confirmationMemoChecksDestinationWithoutRequiringInboundAddress() throws {
        let quote = try BaseThorChainMultiSwapProvider.SwapQuote(JSONString: Self.json(inboundAddress: nil))
        let memo = try quote.requiredMemo(expectedDestination: "bc1qexample", blockchainType: .bitcoin)
        #expect(memo == quote.memo)
        #expect(quote.inboundAddress == nil)
    }

    @Test func confirmationMemoRejectsWrongRecipientBeforeTransactionConstruction() throws {
        let quote = try BaseThorChainMultiSwapProvider.SwapQuote(JSONString: Self.json(inboundAddress: "bc1qvault"))
        #expect(throws: ThorChainSwapMemo.ValidationError.destinationMismatch) {
            _ = try quote.requiredMemo(expectedDestination: "bc1qdifferent", blockchainType: .bitcoin)
        }
    }

    @Test func dryQuoteCanStillDecodeWithoutMemo() throws {
        let json = Self.json(inboundAddress: nil).replacingOccurrences(of: ",\"memo\":\"=:BTC.BTC:bc1qexample\"", with: "")
        let quote = try BaseThorChainMultiSwapProvider.SwapQuote(JSONString: json)
        #expect(quote.memo == nil)
        do {
            _ = try quote.requiredMemo(expectedDestination: "bc1qexample", blockchainType: .bitcoin)
            Issue.record("Confirmation must reject a missing memo")
        } catch BaseThorChainMultiSwapProvider.SwapError.noMemo {
            // Existing no-memo error is preserved.
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    private static func json(inboundAddress: String?) -> String {
        let inbound = inboundAddress.map { "\"inbound_address\":\"\($0)\"," } ?? ""
        return """
        {\(inbound)"expected_amount_out":"12345678","memo":"=:BTC.BTC:bc1qexample",
         "fees":{"affiliate":"1","outbound":"2","liquidity":"3","total":"6"}}
        """
    }
}

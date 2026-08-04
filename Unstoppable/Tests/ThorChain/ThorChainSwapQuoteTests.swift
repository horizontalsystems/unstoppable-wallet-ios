import Foundation
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

    private static func json(inboundAddress: String?) -> String {
        let inbound = inboundAddress.map { "\"inbound_address\":\"\($0)\"," } ?? ""
        return """
        {\(inbound)"expected_amount_out":"12345678","memo":"=:BTC.BTC:bc1qexample",
         "fees":{"affiliate":"1","outbound":"2","liquidity":"3","total":"6"}}
        """
    }
}

import BigInt
import Testing
@testable import WalletCore

struct WCNSwapNativeValueVerifierTests {
    private let verifier = WCNSwapNativeValueVerifier()

    @Test func ignoresNonSwapTransactions() throws {
        let parsed = try WCNStubParsedRequest.make()
        parsed.stubValue = 1
        let parsedContext = try WCNTestFixtures.context(parsed: parsed)
        #expect(verifier.handles(parsedContext) == false)
    }

    @Test func blocksTokenSwapWithNativeValue() throws {
        let parsed = try WCNStubParsedRequest.make()
        parsed.stubSwapInfo = WCNSwapInfo(provider: .oneInch, tokenInIsNative: false)
        parsed.stubValue = BigUInt(1_000_000_000_000_000)
        let context = try WCNTestFixtures.context(parsed: parsed)

        #expect(verifier.handles(context))
        #expect(verifier.verify(context) == .block(reason: "Token swap carries native value"))
    }

    @Test func passesTokenSwapWithZeroValue() throws {
        let parsed = try WCNStubParsedRequest.make()
        parsed.stubSwapInfo = WCNSwapInfo(provider: .uniswap, tokenInIsNative: false)
        parsed.stubValue = 0
        let verdict = try verifier.verify(WCNTestFixtures.context(parsed: parsed))
        #expect(verdict == .pass)
    }

    @Test func passesNativeSwapWithValue() throws {
        let parsed = try WCNStubParsedRequest.make()
        parsed.stubSwapInfo = WCNSwapInfo(provider: .oneInch, tokenInIsNative: true)
        parsed.stubValue = BigUInt(1_000_000_000_000_000)
        let verdict = try verifier.verify(WCNTestFixtures.context(parsed: parsed))
        #expect(verdict == .pass)
    }
}

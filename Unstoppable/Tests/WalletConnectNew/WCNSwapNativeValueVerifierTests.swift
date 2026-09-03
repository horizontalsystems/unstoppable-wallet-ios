import BigInt
import Testing
@testable import WalletCore

struct WCNSwapNativeValueVerifierTests {
    private let verifier = WCNSwapNativeValueVerifier()

    @Test func ignoresNonSwapTransactions() throws {
        let payload = try WCNStubRequestPayload.make()
        payload.stubValue = 1
        let parsedContext = try WCNTestFixtures.context(payload: payload)
        #expect(verifier.handles(parsedContext) == false)
    }

    @Test func blocksTokenSwapWithNativeValue() throws {
        let payload = try WCNStubRequestPayload.make()
        payload.stubSwapInfo = WCNSwapInfo(provider: .oneInch, tokenInIsNative: false)
        payload.stubValue = BigUInt(1_000_000_000_000_000)
        let context = try WCNTestFixtures.context(payload: payload)

        #expect(verifier.handles(context))
        #expect(verifier.verify(context) == .block(reason: .tokenSwapCarriesNativeValue))
    }

    @Test func passesTokenSwapWithZeroValue() throws {
        let payload = try WCNStubRequestPayload.make()
        payload.stubSwapInfo = WCNSwapInfo(provider: .uniswap, tokenInIsNative: false)
        payload.stubValue = 0
        let verdict = try verifier.verify(WCNTestFixtures.context(payload: payload))
        #expect(verdict == .pass)
    }

    @Test func passesNativeSwapWithValue() throws {
        let payload = try WCNStubRequestPayload.make()
        payload.stubSwapInfo = WCNSwapInfo(provider: .oneInch, tokenInIsNative: true)
        payload.stubValue = BigUInt(1_000_000_000_000_000)
        let verdict = try verifier.verify(WCNTestFixtures.context(payload: payload))
        #expect(verdict == .pass)
    }
}

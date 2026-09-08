import BigInt
import Testing
@testable import WalletCore

struct WCSwapNativeValueVerifierTests {
    private let verifier = WCSwapNativeValueVerifier()

    @Test func ignoresNonSwapTransactions() throws {
        let payload = try WCStubRequestPayload.make()
        payload.stubValue = 1
        let parsedContext = try WCTestFixtures.context(payload: payload)
        #expect(verifier.handles(parsedContext) == false)
    }

    @Test func blocksTokenSwapWithNativeValue() throws {
        let payload = try WCStubRequestPayload.make()
        payload.stubSwapInfo = WCSwapInfo(provider: .oneInch, tokenInIsNative: false)
        payload.stubValue = BigUInt(1_000_000_000_000_000)
        let context = try WCTestFixtures.context(payload: payload)

        #expect(verifier.handles(context))
        #expect(verifier.verify(context) == .block(reason: .tokenSwapCarriesNativeValue))
    }

    @Test func passesTokenSwapWithZeroValue() throws {
        let payload = try WCStubRequestPayload.make()
        payload.stubSwapInfo = WCSwapInfo(provider: .uniswap, tokenInIsNative: false)
        payload.stubValue = 0
        let verdict = try verifier.verify(WCTestFixtures.context(payload: payload))
        #expect(verdict == .pass)
    }

    @Test func passesNativeSwapWithValue() throws {
        let payload = try WCStubRequestPayload.make()
        payload.stubSwapInfo = WCSwapInfo(provider: .oneInch, tokenInIsNative: true)
        payload.stubValue = BigUInt(1_000_000_000_000_000)
        let verdict = try verifier.verify(WCTestFixtures.context(payload: payload))
        #expect(verdict == .pass)
    }
}

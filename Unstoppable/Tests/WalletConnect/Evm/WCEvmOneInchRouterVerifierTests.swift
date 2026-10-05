import Testing
@testable import WalletCore

struct WCEvmOneInchRouterVerifierTests {
    private let routers = WCStubSwapRouterProvider()

    private func makeVerifier() -> WCEvmOneInchRouterVerifier {
        routers.routers["eip155:1"] = WCTestFixtures.oneInchRouter
        return WCEvmOneInchRouterVerifier(routerProvider: routers)
    }

    @Test func handlesOnlyOneInchSwaps() throws {
        let verifier = makeVerifier()
        let uniswap = try WCStubRequestPayload.make()
        uniswap.stubSwapInfo = WCSwapInfo(provider: .uniswap, tokenInIsNative: true)
        let oneInch = try WCStubRequestPayload.make()
        oneInch.stubSwapInfo = WCSwapInfo(provider: .oneInch, tokenInIsNative: true)

        let uniswapContext = try WCTestFixtures.context(payload: uniswap)

        #expect(verifier.handles(uniswapContext) == false)
        let oneInchContext = try WCTestFixtures.context(payload: oneInch)
        #expect(verifier.handles(oneInchContext))
    }

    @Test func blocksSwapToForeignAddress() throws {
        let verifier = makeVerifier()
        let payload = try WCStubRequestPayload.make()
        payload.stubSwapInfo = WCSwapInfo(provider: .oneInch, tokenInIsNative: false)
        payload.stubTo = "0x000000000000000000000000000000000000dEaD"

        let verdict = try verifier.verify(WCTestFixtures.context(payload: payload))
        #expect(verdict == .block(reason: .swapNotToCanonicalRouter))
    }

    @Test func passesCanonicalRouterCaseInsensitively() throws {
        let verifier = makeVerifier()
        let payload = try WCStubRequestPayload.make()
        payload.stubSwapInfo = WCSwapInfo(provider: .oneInch, tokenInIsNative: false)
        payload.stubTo = WCTestFixtures.oneInchRouter.lowercased()

        let verdict = try verifier.verify(WCTestFixtures.context(payload: payload))
        #expect(verdict == .pass)
    }

    @Test func blocksChainWithoutRouter() throws {
        let verifier = makeVerifier()
        let payload = try WCStubRequestPayload.make(chainId: "eip155:999")
        payload.stubSwapInfo = WCSwapInfo(provider: .oneInch, tokenInIsNative: false)
        payload.stubTo = WCTestFixtures.oneInchRouter

        let verdict = try verifier.verify(WCTestFixtures.context(payload: payload))
        #expect(verdict == .block(reason: .swapRouterUnsupported(chain: "eip155:999")))
    }

    @Test func blocksMissingTo() throws {
        let verifier = makeVerifier()
        let payload = try WCStubRequestPayload.make()
        payload.stubSwapInfo = WCSwapInfo(provider: .oneInch, tokenInIsNative: false)

        let verdict = try verifier.verify(WCTestFixtures.context(payload: payload))
        #expect(verdict == .block(reason: .swapNotToCanonicalRouter))
    }
}

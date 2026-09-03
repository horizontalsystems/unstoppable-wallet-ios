import Testing
@testable import WalletCore

struct WCNEvmOneInchRouterVerifierTests {
    private let routers = WCNStubSwapRouterProvider()

    private func makeVerifier() -> WCNEvmOneInchRouterVerifier {
        routers.routers["eip155:1"] = WCNTestFixtures.oneInchRouter
        return WCNEvmOneInchRouterVerifier(routerProvider: routers)
    }

    @Test func handlesOnlyOneInchSwaps() throws {
        let verifier = makeVerifier()
        let uniswap = try WCNStubRequestPayload.make()
        uniswap.stubSwapInfo = WCNSwapInfo(provider: .uniswap, tokenInIsNative: true)
        let oneInch = try WCNStubRequestPayload.make()
        oneInch.stubSwapInfo = WCNSwapInfo(provider: .oneInch, tokenInIsNative: true)

        let uniswapContext = try WCNTestFixtures.context(payload: uniswap)

        #expect(verifier.handles(uniswapContext) == false)
        let oneInchContext = try WCNTestFixtures.context(payload: oneInch)
        #expect(verifier.handles(oneInchContext))
    }

    @Test func blocksSwapToForeignAddress() throws {
        let verifier = makeVerifier()
        let payload = try WCNStubRequestPayload.make()
        payload.stubSwapInfo = WCNSwapInfo(provider: .oneInch, tokenInIsNative: false)
        payload.stubTo = "0x000000000000000000000000000000000000dEaD"

        let verdict = try verifier.verify(WCNTestFixtures.context(payload: payload))
        #expect(verdict == .block(reason: .swapNotToCanonicalRouter))
    }

    @Test func passesCanonicalRouterCaseInsensitively() throws {
        let verifier = makeVerifier()
        let payload = try WCNStubRequestPayload.make()
        payload.stubSwapInfo = WCNSwapInfo(provider: .oneInch, tokenInIsNative: false)
        payload.stubTo = WCNTestFixtures.oneInchRouter.lowercased()

        let verdict = try verifier.verify(WCNTestFixtures.context(payload: payload))
        #expect(verdict == .pass)
    }

    @Test func blocksChainWithoutRouter() throws {
        let verifier = makeVerifier()
        let payload = try WCNStubRequestPayload.make(chainId: "eip155:999")
        payload.stubSwapInfo = WCNSwapInfo(provider: .oneInch, tokenInIsNative: false)
        payload.stubTo = WCNTestFixtures.oneInchRouter

        let verdict = try verifier.verify(WCNTestFixtures.context(payload: payload))
        #expect(verdict == .block(reason: .swapRouterUnsupported(chain: "eip155:999")))
    }

    @Test func blocksMissingTo() throws {
        let verifier = makeVerifier()
        let payload = try WCNStubRequestPayload.make()
        payload.stubSwapInfo = WCNSwapInfo(provider: .oneInch, tokenInIsNative: false)

        let verdict = try verifier.verify(WCNTestFixtures.context(payload: payload))
        #expect(verdict == .block(reason: .swapNotToCanonicalRouter))
    }
}

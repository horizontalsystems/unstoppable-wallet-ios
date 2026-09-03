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
        let uniswap = try WCNStubParsedRequest.make()
        uniswap.stubSwapInfo = WCNSwapInfo(provider: .uniswap, tokenInIsNative: true)
        let oneInch = try WCNStubParsedRequest.make()
        oneInch.stubSwapInfo = WCNSwapInfo(provider: .oneInch, tokenInIsNative: true)

        let uniswapContext = try WCNTestFixtures.context(parsed: uniswap)

        #expect(verifier.handles(uniswapContext) == false)
        let oneInchContext = try WCNTestFixtures.context(parsed: oneInch)
        #expect(verifier.handles(oneInchContext))
    }

    @Test func blocksSwapToForeignAddress() throws {
        let verifier = makeVerifier()
        let parsed = try WCNStubParsedRequest.make()
        parsed.stubSwapInfo = WCNSwapInfo(provider: .oneInch, tokenInIsNative: false)
        parsed.stubTo = "0x000000000000000000000000000000000000dEaD"

        let verdict = try verifier.verify(WCNTestFixtures.context(parsed: parsed))
        #expect(verdict == .block(reason: "1inch swap is not addressed to the canonical router"))
    }

    @Test func passesCanonicalRouterCaseInsensitively() throws {
        let verifier = makeVerifier()
        let parsed = try WCNStubParsedRequest.make()
        parsed.stubSwapInfo = WCNSwapInfo(provider: .oneInch, tokenInIsNative: false)
        parsed.stubTo = WCNTestFixtures.oneInchRouter.lowercased()

        let verdict = try verifier.verify(WCNTestFixtures.context(parsed: parsed))
        #expect(verdict == .pass)
    }

    @Test func blocksChainWithoutRouter() throws {
        let verifier = makeVerifier()
        let parsed = try WCNStubParsedRequest.make(chainId: "eip155:999")
        parsed.stubSwapInfo = WCNSwapInfo(provider: .oneInch, tokenInIsNative: false)
        parsed.stubTo = WCNTestFixtures.oneInchRouter

        let verdict = try verifier.verify(WCNTestFixtures.context(parsed: parsed))
        #expect(verdict == .block(reason: "1inch is not supported on eip155:999"))
    }

    @Test func blocksMissingTo() throws {
        let verifier = makeVerifier()
        let parsed = try WCNStubParsedRequest.make()
        parsed.stubSwapInfo = WCNSwapInfo(provider: .oneInch, tokenInIsNative: false)

        let verdict = try verifier.verify(WCNTestFixtures.context(parsed: parsed))
        #expect(verdict == .block(reason: "1inch swap is not addressed to the canonical router"))
    }
}

import Testing
@testable import WalletCore

struct WCSessionScopeVerifierTests {
    private let verifier = WCSessionScopeVerifier()

    @Test func passesChainWithApprovedAccount() throws {
        let context = try WCTestFixtures.context(payload: WCStubRequestPayload.make(chainId: "eip155:10"), approvedAccounts: [WCTestFixtures.approvedMainnet, WCTestFixtures.approvedOptimism])
        #expect(verifier.verify(context) == .pass)
    }

    @Test func blocksChainOutsideSession() throws {
        let context = try WCTestFixtures.context(payload: WCStubRequestPayload.make(chainId: "eip155:56"), approvedAccounts: [WCTestFixtures.approvedMainnet])
        #expect(verifier.verify(context) == .block(reason: .chainNotInSession(chain: "eip155:56")))
    }

    @Test func blocksWhenNothingApproved() throws {
        let context = try WCTestFixtures.context(payload: WCStubRequestPayload.make(kind: .direct, from: nil))
        #expect(verifier.handles(context))
        #expect(verifier.verify(context) == .block(reason: .chainNotInSession(chain: "eip155:1")))
    }
}

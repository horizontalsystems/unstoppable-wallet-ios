import Testing
@testable import WalletCore

struct WCNSessionScopeVerifierTests {
    private let verifier = WCNSessionScopeVerifier()

    @Test func passesChainWithApprovedAccount() throws {
        let context = try WCNTestFixtures.context(payload: WCNStubRequestPayload.make(chainId: "eip155:10"), approvedAccounts: [WCNTestFixtures.approvedMainnet, WCNTestFixtures.approvedOptimism])
        #expect(verifier.verify(context) == .pass)
    }

    @Test func blocksChainOutsideSession() throws {
        let context = try WCNTestFixtures.context(payload: WCNStubRequestPayload.make(chainId: "eip155:56"), approvedAccounts: [WCNTestFixtures.approvedMainnet])
        #expect(verifier.verify(context) == .block(reason: .chainNotInSession(chain: "eip155:56")))
    }

    @Test func blocksWhenNothingApproved() throws {
        let context = try WCNTestFixtures.context(payload: WCNStubRequestPayload.make(kind: .direct, from: nil))
        #expect(verifier.handles(context))
        #expect(verifier.verify(context) == .block(reason: .chainNotInSession(chain: "eip155:1")))
    }
}

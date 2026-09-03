import Testing
@testable import WalletCore

struct WCNSessionScopeVerifierTests {
    private let verifier = WCNSessionScopeVerifier()

    @Test func passesChainWithApprovedAccount() throws {
        let context = try WCNTestFixtures.context(parsed: WCNStubParsedRequest.make(chainId: "eip155:10"), approvedAccounts: [WCNTestFixtures.approvedMainnet, WCNTestFixtures.approvedOptimism])
        #expect(verifier.verify(context) == .pass)
    }

    @Test func blocksChainOutsideSession() throws {
        let context = try WCNTestFixtures.context(parsed: WCNStubParsedRequest.make(chainId: "eip155:56"), approvedAccounts: [WCNTestFixtures.approvedMainnet])
        #expect(verifier.verify(context) == .block(reason: "Chain eip155:56 is not part of the approved session"))
    }

    @Test func blocksWhenNothingApproved() throws {
        let context = try WCNTestFixtures.context(parsed: WCNStubParsedRequest.make(kind: .direct, from: nil))
        #expect(verifier.handles(context))
        #expect(verifier.verify(context) == .block(reason: "Chain eip155:1 is not part of the approved session"))
    }
}

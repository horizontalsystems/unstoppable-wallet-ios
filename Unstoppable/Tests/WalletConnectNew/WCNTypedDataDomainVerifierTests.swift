import Testing
@testable import WalletCore

struct WCNTypedDataDomainVerifierTests {
    private let verifier = WCNTypedDataDomainVerifier()

    @Test func ignoresRequestsWithoutDomain() throws {
        let parsed = try WCNStubParsedRequest.make(method: "personal_sign", kind: .signMessage)
        let parsedContext = try WCNTestFixtures.context(parsed: parsed)
        #expect(verifier.handles(parsedContext) == false)
    }

    @Test func passesDomainOnApprovedChain() throws {
        let parsed = try WCNStubParsedRequest.make(method: "eth_signTypedData_v4", kind: .signMessage)
        parsed.stubDomain = WCNTypedDataDomain(chainId: 1, verifyingContract: "0xdAC17F958D2ee523a2206206994597C13D831ec7")
        let context = try WCNTestFixtures.context(parsed: parsed, approvedAccounts: [WCNTestFixtures.approvedMainnet])

        #expect(verifier.handles(context))
        #expect(verifier.verify(context) == .pass)
    }

    @Test func blocksDomainOnForeignChain() throws {
        let parsed = try WCNStubParsedRequest.make(method: "eth_signTypedData_v4", kind: .signMessage)
        parsed.stubDomain = WCNTypedDataDomain(chainId: 56, verifyingContract: nil)
        let context = try WCNTestFixtures.context(parsed: parsed, approvedAccounts: [WCNTestFixtures.approvedMainnet])

        #expect(verifier.verify(context) == .block(reason: "Typed data domain chainId 56 is not approved"))
    }

    @Test func cautionsDomainWithoutChainId() throws {
        let parsed = try WCNStubParsedRequest.make(method: "eth_signTypedData_v4", kind: .signMessage)
        parsed.stubDomain = WCNTypedDataDomain(chainId: nil, verifyingContract: nil)
        let context = try WCNTestFixtures.context(parsed: parsed, approvedAccounts: [WCNTestFixtures.approvedMainnet])

        #expect(verifier.verify(context) == .caution(reason: "Typed data domain has no chainId, signature is replayable across chains"))
    }
}

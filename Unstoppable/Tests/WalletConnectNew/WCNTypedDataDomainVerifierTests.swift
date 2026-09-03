import Testing
@testable import WalletCore

struct WCNTypedDataDomainVerifierTests {
    private let verifier = WCNTypedDataDomainVerifier()

    @Test func ignoresRequestsWithoutDomain() throws {
        let payload = try WCNStubRequestPayload.make(method: "personal_sign", kind: .signMessage)
        let parsedContext = try WCNTestFixtures.context(payload: payload)
        #expect(verifier.handles(parsedContext) == false)
    }

    @Test func passesDomainOnApprovedChain() throws {
        let payload = try WCNStubRequestPayload.make(method: "eth_signTypedData_v4", kind: .signMessage)
        payload.stubDomain = WCNTypedDataDomain(chainId: 1, verifyingContract: "0xdAC17F958D2ee523a2206206994597C13D831ec7")
        let context = try WCNTestFixtures.context(payload: payload, approvedAccounts: [WCNTestFixtures.approvedMainnet])

        #expect(verifier.handles(context))
        #expect(verifier.verify(context) == .pass)
    }

    @Test func blocksDomainOnForeignChain() throws {
        let payload = try WCNStubRequestPayload.make(method: "eth_signTypedData_v4", kind: .signMessage)
        payload.stubDomain = WCNTypedDataDomain(chainId: 56, verifyingContract: nil)
        let context = try WCNTestFixtures.context(payload: payload, approvedAccounts: [WCNTestFixtures.approvedMainnet])

        #expect(verifier.verify(context) == .block(reason: .typedDataDomainChainNotApproved(chainId: 56)))
    }

    @Test func cautionsDomainWithoutChainId() throws {
        let payload = try WCNStubRequestPayload.make(method: "eth_signTypedData_v4", kind: .signMessage)
        payload.stubDomain = WCNTypedDataDomain(chainId: nil, verifyingContract: nil)
        let context = try WCNTestFixtures.context(payload: payload, approvedAccounts: [WCNTestFixtures.approvedMainnet])

        #expect(verifier.verify(context) == .caution(reason: .typedDataDomainWithoutChain))
    }
}

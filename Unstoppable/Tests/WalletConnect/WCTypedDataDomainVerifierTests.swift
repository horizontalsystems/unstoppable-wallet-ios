import Testing
@testable import WalletCore

struct WCTypedDataDomainVerifierTests {
    private let verifier = WCTypedDataDomainVerifier()

    @Test func ignoresRequestsWithoutDomain() throws {
        let payload = try WCStubRequestPayload.make(method: "personal_sign", kind: .signMessage)
        let parsedContext = try WCTestFixtures.context(payload: payload)
        #expect(verifier.handles(parsedContext) == false)
    }

    @Test func passesDomainOnApprovedChain() throws {
        let payload = try WCStubRequestPayload.make(method: "eth_signTypedData_v4", kind: .signMessage)
        payload.stubDomain = WCTypedDataDomain(chainId: 1, verifyingContract: "0xdAC17F958D2ee523a2206206994597C13D831ec7")
        let context = try WCTestFixtures.context(payload: payload, approvedAccounts: [WCTestFixtures.approvedMainnet])

        #expect(verifier.handles(context))
        #expect(verifier.verify(context) == .pass)
    }

    @Test func blocksDomainOnForeignChain() throws {
        let payload = try WCStubRequestPayload.make(method: "eth_signTypedData_v4", kind: .signMessage)
        payload.stubDomain = WCTypedDataDomain(chainId: 56, verifyingContract: nil)
        let context = try WCTestFixtures.context(payload: payload, approvedAccounts: [WCTestFixtures.approvedMainnet])

        #expect(verifier.verify(context) == .block(reason: .typedDataDomainChainNotApproved(chainId: 56)))
    }

    @Test func cautionsDomainWithoutChainId() throws {
        let payload = try WCStubRequestPayload.make(method: "eth_signTypedData_v4", kind: .signMessage)
        payload.stubDomain = WCTypedDataDomain(chainId: nil, verifyingContract: nil)
        let context = try WCTestFixtures.context(payload: payload, approvedAccounts: [WCTestFixtures.approvedMainnet])

        #expect(verifier.verify(context) == .caution(reason: .typedDataDomainWithoutChain))
    }
}

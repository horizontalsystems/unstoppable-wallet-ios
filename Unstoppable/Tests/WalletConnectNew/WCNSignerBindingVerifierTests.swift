import Testing
@testable import WalletCore

struct WCNSignerBindingVerifierTests {
    private let verifier = WCNSignerBindingVerifier()

    @Test func skipsDirectResponseRequests() throws {
        let payload = try WCNStubRequestPayload.make(method: "wallet_switchEthereumChain", kind: .direct, from: nil)
        let parsedContext = try WCNTestFixtures.context(payload: payload)
        #expect(verifier.handles(parsedContext) == false)
    }

    @Test func passesApprovedSignerOnExactChain() throws {
        let context = try WCNTestFixtures.context(payload: WCNStubRequestPayload.make(), approvedAccounts: [WCNTestFixtures.approvedMainnet])
        #expect(verifier.verify(context) == .pass)
    }

    @Test func comparesAddressesCaseInsensitively() throws {
        let payload = try WCNStubRequestPayload.make(from: WCNTestFixtures.address.lowercased())
        let context = try WCNTestFixtures.context(payload: payload, approvedAccounts: [WCNTestFixtures.approvedMainnet])
        #expect(verifier.verify(context) == .pass)
    }

    @Test func worksForNonEvmNamespace() throws {
        let stellar = "GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H"
        let payload = try WCNStubRequestPayload.make(method: "stellar_signXDR", chainId: "stellar:pubnet", kind: .transaction, from: stellar)
        let context = try WCNTestFixtures.context(payload: payload, approvedAccounts: [WCNTestFixtures.account("stellar:pubnet:\(stellar)")])
        #expect(verifier.verify(context) == .pass)
    }

    @Test func blocksSignerApprovedOnlyForOtherChain() throws {
        let context = try WCNTestFixtures.context(payload: WCNStubRequestPayload.make(chainId: "eip155:1"), approvedAccounts: [WCNTestFixtures.approvedOptimism])
        #expect(verifier.verify(context) == .block(reason: .signerNotApproved(chain: "eip155:1")))
    }

    @Test func blocksForeignSigner() throws {
        let payload = try WCNStubRequestPayload.make(from: "0x000000000000000000000000000000000000dEaD")
        let context = try WCNTestFixtures.context(payload: payload, approvedAccounts: [WCNTestFixtures.approvedMainnet])
        #expect(verifier.verify(context) == .block(reason: .signerNotApproved(chain: "eip155:1")))
    }

    @Test func blocksMissingSignerByDefault() throws {
        let payload = try WCNStubRequestPayload.make(method: "personal_sign", kind: .signMessage, from: nil)
        let context = try WCNTestFixtures.context(payload: payload, approvedAccounts: [WCNTestFixtures.approvedMainnet])
        #expect(verifier.verify(context) == .block(reason: .missingSigner))
    }

    @Test func missingSignerPassesWhenFlagOff() throws {
        let lenient = WCNSignerBindingVerifier(requireSigner: false)
        let payload = try WCNStubRequestPayload.make(method: "personal_sign", kind: .signMessage, from: nil)
        let context = try WCNTestFixtures.context(payload: payload, approvedAccounts: [WCNTestFixtures.approvedMainnet])
        #expect(lenient.verify(context) == .pass)
    }

    @Test func blocksMalformedSigner() throws {
        let payload = try WCNStubRequestPayload.make(from: "not an address with spaces")
        let context = try WCNTestFixtures.context(payload: payload, approvedAccounts: [WCNTestFixtures.approvedMainnet])
        #expect(verifier.verify(context) == .block(reason: .malformedSigner))
    }
}

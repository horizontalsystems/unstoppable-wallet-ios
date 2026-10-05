import Testing
@testable import WalletCore

struct WCSignerBindingVerifierTests {
    private let verifier = WCSignerBindingVerifier()

    @Test func skipsDirectResponseRequests() throws {
        let payload = try WCStubRequestPayload.make(method: "wallet_switchEthereumChain", kind: .direct, from: nil)
        let parsedContext = try WCTestFixtures.context(payload: payload)
        #expect(verifier.handles(parsedContext) == false)
    }

    @Test func passesApprovedSignerOnExactChain() throws {
        let context = try WCTestFixtures.context(payload: WCStubRequestPayload.make(), approvedAccounts: [WCTestFixtures.approvedMainnet])
        #expect(verifier.verify(context) == .pass)
    }

    @Test func comparesAddressesCaseInsensitively() throws {
        let payload = try WCStubRequestPayload.make(from: WCTestFixtures.address.lowercased())
        let context = try WCTestFixtures.context(payload: payload, approvedAccounts: [WCTestFixtures.approvedMainnet])
        #expect(verifier.verify(context) == .pass)
    }

    @Test func worksForNonEvmNamespace() throws {
        let stellar = "GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H"
        let payload = try WCStubRequestPayload.make(method: "stellar_signXDR", chainId: "stellar:pubnet", kind: .transaction, from: stellar)
        let context = try WCTestFixtures.context(payload: payload, approvedAccounts: [WCTestFixtures.account("stellar:pubnet:\(stellar)")])
        #expect(verifier.verify(context) == .pass)
    }

    @Test func blocksSignerApprovedOnlyForOtherChain() throws {
        let context = try WCTestFixtures.context(payload: WCStubRequestPayload.make(chainId: "eip155:1"), approvedAccounts: [WCTestFixtures.approvedOptimism])
        #expect(verifier.verify(context) == .block(reason: .signerNotApproved(chain: "eip155:1")))
    }

    @Test func blocksForeignSigner() throws {
        let payload = try WCStubRequestPayload.make(from: "0x000000000000000000000000000000000000dEaD")
        let context = try WCTestFixtures.context(payload: payload, approvedAccounts: [WCTestFixtures.approvedMainnet])
        #expect(verifier.verify(context) == .block(reason: .signerNotApproved(chain: "eip155:1")))
    }

    @Test func blocksMissingSignerByDefault() throws {
        let payload = try WCStubRequestPayload.make(method: "personal_sign", kind: .signMessage, from: nil)
        let context = try WCTestFixtures.context(payload: payload, approvedAccounts: [WCTestFixtures.approvedMainnet])
        #expect(verifier.verify(context) == .block(reason: .missingSigner))
    }

    @Test func missingSignerPassesWhenFlagOff() throws {
        let lenient = WCSignerBindingVerifier(requireSigner: false)
        let payload = try WCStubRequestPayload.make(method: "personal_sign", kind: .signMessage, from: nil)
        let context = try WCTestFixtures.context(payload: payload, approvedAccounts: [WCTestFixtures.approvedMainnet])
        #expect(lenient.verify(context) == .pass)
    }

    @Test func blocksMalformedSigner() throws {
        let payload = try WCStubRequestPayload.make(from: "not an address with spaces")
        let context = try WCTestFixtures.context(payload: payload, approvedAccounts: [WCTestFixtures.approvedMainnet])
        #expect(verifier.verify(context) == .block(reason: .malformedSigner))
    }
}

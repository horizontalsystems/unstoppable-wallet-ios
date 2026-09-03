import Testing
@testable import WalletCore

struct WCNSignerBindingVerifierTests {
    private let verifier = WCNSignerBindingVerifier()

    @Test func skipsDirectResponseRequests() throws {
        let parsed = try WCNStubParsedRequest.make(method: "wallet_switchEthereumChain", kind: .direct, from: nil)
        let parsedContext = try WCNTestFixtures.context(parsed: parsed)
        #expect(verifier.handles(parsedContext) == false)
    }

    @Test func passesApprovedSignerOnExactChain() throws {
        let context = try WCNTestFixtures.context(parsed: WCNStubParsedRequest.make(), approvedAccounts: [WCNTestFixtures.approvedMainnet])
        #expect(verifier.verify(context) == .pass)
    }

    @Test func comparesAddressesCaseInsensitively() throws {
        let parsed = try WCNStubParsedRequest.make(from: WCNTestFixtures.address.lowercased())
        let context = try WCNTestFixtures.context(parsed: parsed, approvedAccounts: [WCNTestFixtures.approvedMainnet])
        #expect(verifier.verify(context) == .pass)
    }

    @Test func worksForNonEvmNamespace() throws {
        let stellar = "GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H"
        let parsed = try WCNStubParsedRequest.make(method: "stellar_signXDR", chainId: "stellar:pubnet", kind: .transaction, from: stellar)
        let context = try WCNTestFixtures.context(parsed: parsed, approvedAccounts: [WCNTestFixtures.account("stellar:pubnet:\(stellar)")])
        #expect(verifier.verify(context) == .pass)
    }

    @Test func blocksSignerApprovedOnlyForOtherChain() throws {
        let context = try WCNTestFixtures.context(parsed: WCNStubParsedRequest.make(chainId: "eip155:1"), approvedAccounts: [WCNTestFixtures.approvedOptimism])
        #expect(verifier.verify(context) == .block(reason: "Signing address is not approved for eip155:1"))
    }

    @Test func blocksForeignSigner() throws {
        let parsed = try WCNStubParsedRequest.make(from: "0x000000000000000000000000000000000000dEaD")
        let context = try WCNTestFixtures.context(parsed: parsed, approvedAccounts: [WCNTestFixtures.approvedMainnet])
        #expect(verifier.verify(context) == .block(reason: "Signing address is not approved for eip155:1"))
    }

    @Test func blocksMissingSignerByDefault() throws {
        let parsed = try WCNStubParsedRequest.make(method: "personal_sign", kind: .signMessage, from: nil)
        let context = try WCNTestFixtures.context(parsed: parsed, approvedAccounts: [WCNTestFixtures.approvedMainnet])
        #expect(verifier.verify(context) == .block(reason: "Request does not specify the signing address"))
    }

    @Test func missingSignerPassesWhenFlagOff() throws {
        let lenient = WCNSignerBindingVerifier(requireSigner: false)
        let parsed = try WCNStubParsedRequest.make(method: "personal_sign", kind: .signMessage, from: nil)
        let context = try WCNTestFixtures.context(parsed: parsed, approvedAccounts: [WCNTestFixtures.approvedMainnet])
        #expect(lenient.verify(context) == .pass)
    }

    @Test func blocksMalformedSigner() throws {
        let parsed = try WCNStubParsedRequest.make(from: "not an address with spaces")
        let context = try WCNTestFixtures.context(parsed: parsed, approvedAccounts: [WCNTestFixtures.approvedMainnet])
        #expect(verifier.verify(context) == .block(reason: "Signing address is malformed"))
    }
}

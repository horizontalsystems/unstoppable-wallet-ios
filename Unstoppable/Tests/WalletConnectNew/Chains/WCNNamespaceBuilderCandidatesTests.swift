import Testing
import WalletConnectSign
@testable import WalletCore

struct WCNNamespaceBuilderCandidatesTests {
    private let builder = WCNChainSupportFixtures.builder()
    private let account = WCNChainSupportFixtures.walletAccount

    @Test func spikeProposalYieldsOptionalCandidates() {
        let candidates = builder.candidates(required: [:], optional: WCNChainSupportFixtures.spikeOptional, account: account)

        #expect(candidates.map(\.chain.absoluteString) == ["eip155:1", "eip155:10"])
        #expect(candidates.allSatisfy { !$0.required })
        #expect(candidates[0].account.absoluteString == "eip155:1:\(WCNTestFixtures.address)")
        #expect(candidates[0].methods == ["eth_sendTransaction", "personal_sign"])
        #expect(candidates[0].events == ["accountsChanged", "chainChanged"])
    }

    @Test func requiredChainIsFlaggedAndMergedWithOptional() {
        let required = ["eip155": WCNChainSupportFixtures.namespace(["eip155:1"], methods: ["personal_sign"], events: [])]
        let optional = ["eip155": WCNChainSupportFixtures.namespace(["eip155:1", "eip155:10"], methods: ["eth_sendTransaction"], events: ["chainChanged"])]

        let candidates = builder.candidates(required: required, optional: optional, account: account)

        #expect(candidates.count == 2)
        #expect(candidates[0].chain.absoluteString == "eip155:1")
        #expect(candidates[0].required)
        #expect(candidates[0].methods == ["personal_sign", "eth_sendTransaction"])
        #expect(candidates[0].events == ["chainChanged"])
        #expect(candidates[1].required == false)
    }

    @Test func chainScopedKeyWithoutChainsField() {
        let optional = ["eip155:10": WCNChainSupportFixtures.namespace(nil, methods: ["personal_sign"], events: [])]
        let candidates = builder.candidates(required: [:], optional: optional, account: account)
        #expect(candidates.map(\.chain.absoluteString) == ["eip155:10"])
    }

    @Test func unsupportedNamespaceIsSkipped() {
        let optional = ["cosmos": WCNChainSupportFixtures.namespace(["cosmos:cosmoshub-4"], methods: ["cosmos_signDirect"], events: [])]
        #expect(builder.candidates(required: [:], optional: optional, account: account).isEmpty)
    }

    @Test func unsupportedChainIsSkipped() {
        let optional = ["eip155": WCNChainSupportFixtures.namespace(["eip155:999", "eip155:56"], methods: ["personal_sign"], events: [])]
        let candidates = builder.candidates(required: [:], optional: optional, account: account)
        #expect(candidates.map(\.chain.absoluteString) == ["eip155:56"])
    }

    @Test func namespaceKeyWithoutChainsYieldsNothing() {
        let optional = ["eip155": WCNChainSupportFixtures.namespace(nil, methods: ["personal_sign"], events: [])]
        #expect(builder.candidates(required: [:], optional: optional, account: account).isEmpty)
    }

    @Test func methodsAndEventsAreIntersected() {
        let optional = ["eip155": WCNChainSupportFixtures.namespace(["eip155:1"], methods: ["personal_sign", "eth_foo"], events: ["chainChanged", "disconnect"])]
        let candidates = builder.candidates(required: [:], optional: optional, account: account)
        #expect(candidates[0].methods == ["personal_sign"])
        #expect(candidates[0].events == ["chainChanged"])
    }

    @Test func multipleNamespacesInOneProposal() {
        let optional = [
            "eip155": WCNChainSupportFixtures.namespace(["eip155:1"], methods: ["personal_sign"], events: []),
            "stellar": WCNChainSupportFixtures.namespace(["stellar:pubnet"], methods: ["stellar_signXDR"], events: ["message"]),
        ]
        let candidates = builder.candidates(required: [:], optional: optional, account: account)
        #expect(candidates.map(\.chain.absoluteString) == ["eip155:1", "stellar:pubnet"])
        #expect(candidates[1].account.address == WCNChainSupportFixtures.stellarAddress)
    }
}

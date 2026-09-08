import Testing
import WalletConnectSign
@testable import WalletCore

struct WCNNamespaceBuilderProposalsTests {
    private let builder = WCNChainSupportFixtures.builder()
    private let account = WCNChainSupportFixtures.walletAccount

    @Test func spikeProposalYieldsOptionalCandidates() {
        let proposals = builder.proposals(required: [:], optional: WCNChainSupportFixtures.spikeOptional, account: account)

        #expect(proposals.map(\.chain.absoluteString) == ["eip155:1", "eip155:10"])
        #expect(proposals.allSatisfy { !$0.required })
        #expect(proposals[0].account.absoluteString == "eip155:1:\(WCNTestFixtures.address)")
        #expect(proposals[0].methods == ["eth_sendTransaction", "personal_sign"])
        #expect(proposals[0].events == ["accountsChanged", "chainChanged"])
    }

    @Test func requiredChainIsFlaggedAndMergedWithOptional() {
        let required = ["eip155": WCNChainSupportFixtures.namespace(["eip155:1"], methods: ["personal_sign"], events: [])]
        let optional = ["eip155": WCNChainSupportFixtures.namespace(["eip155:1", "eip155:10"], methods: ["eth_sendTransaction"], events: ["chainChanged"])]

        let proposals = builder.proposals(required: required, optional: optional, account: account)

        #expect(proposals.count == 2)
        #expect(proposals[0].chain.absoluteString == "eip155:1")
        #expect(proposals[0].required)
        #expect(proposals[0].methods == ["personal_sign", "eth_sendTransaction"])
        #expect(proposals[0].events == ["chainChanged"])
        #expect(proposals[1].required == false)
    }

    @Test func chainScopedKeyWithoutChainsField() {
        let optional = ["eip155:10": WCNChainSupportFixtures.namespace(nil, methods: ["personal_sign"], events: [])]
        let proposals = builder.proposals(required: [:], optional: optional, account: account)
        #expect(proposals.map(\.chain.absoluteString) == ["eip155:10"])
    }

    @Test func unsupportedNamespaceIsSkipped() {
        let optional = ["cosmos": WCNChainSupportFixtures.namespace(["cosmos:cosmoshub-4"], methods: ["cosmos_signDirect"], events: [])]
        #expect(builder.proposals(required: [:], optional: optional, account: account).isEmpty)
    }

    @Test func emptyNamespaceKeyIsSkippedNotCrashed() {
        let optional = ["": WCNChainSupportFixtures.namespace(["eip155:1"], methods: ["personal_sign"], events: [])]
        #expect(builder.proposals(required: [:], optional: optional, account: account).isEmpty)
    }

    @Test func colonOnlyNamespaceKeyIsSkippedNotCrashed() {
        let optional = [":": WCNChainSupportFixtures.namespace(["eip155:1"], methods: ["personal_sign"], events: [])]
        #expect(builder.proposals(required: [:], optional: optional, account: account).isEmpty)
    }

    @Test func unsupportedChainIsSkipped() {
        let optional = ["eip155": WCNChainSupportFixtures.namespace(["eip155:999", "eip155:56"], methods: ["personal_sign"], events: [])]
        let proposals = builder.proposals(required: [:], optional: optional, account: account)
        #expect(proposals.map(\.chain.absoluteString) == ["eip155:56"])
    }

    @Test func namespaceKeyWithoutChainsYieldsNothing() {
        let optional = ["eip155": WCNChainSupportFixtures.namespace(nil, methods: ["personal_sign"], events: [])]
        #expect(builder.proposals(required: [:], optional: optional, account: account).isEmpty)
    }

    @Test func methodsAndEventsAreIntersected() {
        let optional = ["eip155": WCNChainSupportFixtures.namespace(["eip155:1"], methods: ["personal_sign", "eth_foo"], events: ["chainChanged", "disconnect"])]
        let proposals = builder.proposals(required: [:], optional: optional, account: account)
        #expect(proposals[0].methods == ["personal_sign"])
        #expect(proposals[0].events == ["chainChanged"])
    }

    @Test func multipleNamespacesInOneProposal() {
        let optional = [
            "eip155": WCNChainSupportFixtures.namespace(["eip155:1"], methods: ["personal_sign"], events: []),
            "stellar": WCNChainSupportFixtures.namespace(["stellar:pubnet"], methods: ["stellar_signXDR"], events: ["message"]),
        ]
        let proposals = builder.proposals(required: [:], optional: optional, account: account)
        #expect(proposals.map(\.chain.absoluteString) == ["eip155:1", "stellar:pubnet"])
        #expect(proposals[1].account.address == WCNChainSupportFixtures.stellarAddress)
    }
}

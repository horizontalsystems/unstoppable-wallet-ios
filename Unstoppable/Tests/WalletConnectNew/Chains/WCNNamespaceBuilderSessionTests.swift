import Testing
import WalletConnectSign
@testable import WalletCore

struct WCNNamespaceBuilderSessionTests {
    private let builder = WCNChainSupportFixtures.builder()
    private let account = WCNChainSupportFixtures.walletAccount

    // golden: exactly what the old wallet sent on approve during the 2026-09-02 spike
    @Test func spikeGoldenNamespace() {
        let selected = builder.proposals(required: [:], optional: WCNChainSupportFixtures.spikeOptional, account: account)
        let namespaces = builder.sessionNamespaces(selected: selected)

        let expected = SessionNamespace(
            accounts: [WCNTestFixtures.approvedMainnet, WCNTestFixtures.approvedOptimism],
            methods: ["eth_sendTransaction", "personal_sign"],
            events: ["chainChanged", "accountsChanged"]
        )
        #expect(namespaces == ["eip155": expected])
        #expect(namespaces["eip155"]?.chains == nil)
    }

    @Test func groupsSelectedProposalsByNamespace() {
        let optional = [
            "eip155": WCNChainSupportFixtures.namespace(["eip155:1"], methods: ["personal_sign"], events: []),
            "stellar": WCNChainSupportFixtures.namespace(["stellar:pubnet"], methods: ["stellar_signXDR"], events: ["message"]),
        ]
        let selected = builder.proposals(required: [:], optional: optional, account: account)
        let namespaces = builder.sessionNamespaces(selected: selected)

        #expect(Set(namespaces.keys) == ["eip155", "stellar"])
        #expect(namespaces["stellar"]?.accounts.map(\.address) == [WCNChainSupportFixtures.stellarAddress])
        #expect(namespaces["stellar"]?.methods == ["stellar_signXDR"])
    }

    @Test func emptySelectionYieldsEmptyNamespaces() {
        #expect(builder.sessionNamespaces(selected: []).isEmpty)
    }
}

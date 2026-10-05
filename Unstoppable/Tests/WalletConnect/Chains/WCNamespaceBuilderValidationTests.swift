import Testing
import WalletConnectSign
@testable import WalletCore

struct WCNamespaceBuilderValidationTests {
    private let builder = WCChainSupportFixtures.builder()
    private let account = WCChainSupportFixtures.walletAccount

    private func proposals(required: [String: ProposalNamespace], optional: [String: ProposalNamespace]? = nil) -> [WCBlockchainProposal] {
        builder.proposals(required: required, optional: optional, account: account)
    }

    @Test func optionalOnlyProposalAlwaysValidates() throws {
        let selected = proposals(required: [:], optional: WCChainSupportFixtures.spikeOptional)
        try builder.validate(required: [:], selected: selected)
    }

    @Test func validRequiredSelectionPasses() throws {
        let required = ["eip155": WCChainSupportFixtures.namespace(["eip155:1", "eip155:10"], methods: ["personal_sign"], events: ["chainChanged"])]
        try builder.validate(required: required, selected: proposals(required: required))
    }

    @Test func deselectedRequiredChainFails() {
        let required = ["eip155": WCChainSupportFixtures.namespace(["eip155:1", "eip155:10"], methods: [], events: [])]
        let selected = proposals(required: required).filter { $0.chain.reference == "1" }

        #expect(throws: WCNamespaceBuilder.ValidationError.requiredChainUnsupported("eip155:10")) {
            try builder.validate(required: required, selected: selected)
        }
    }

    @Test func unsupportedRequiredChainFails() {
        let required = ["eip155": WCChainSupportFixtures.namespace(["eip155:1", "eip155:999"], methods: [], events: [])]

        #expect(throws: WCNamespaceBuilder.ValidationError.requiredChainUnsupported("eip155:999")) {
            try builder.validate(required: required, selected: proposals(required: required))
        }
    }

    @Test func unsupportedRequiredMethodFails() {
        let required = ["eip155": WCChainSupportFixtures.namespace(["eip155:1"], methods: ["eth_foo"], events: [])]

        #expect(throws: WCNamespaceBuilder.ValidationError.requiredMethodUnsupported("eth_foo")) {
            try builder.validate(required: required, selected: proposals(required: required))
        }
    }

    @Test func unsupportedRequiredEventFails() {
        let required = ["eip155": WCChainSupportFixtures.namespace(["eip155:1"], methods: [], events: ["disconnect"])]

        #expect(throws: WCNamespaceBuilder.ValidationError.requiredEventUnsupported("disconnect")) {
            try builder.validate(required: required, selected: proposals(required: required))
        }
    }

    @Test func requiredNamespaceWithNothingSelectedFails() {
        let required = ["cosmos": WCChainSupportFixtures.namespace(["cosmos:cosmoshub-4"], methods: [], events: [])]

        #expect(throws: WCNamespaceBuilder.ValidationError.requiredNamespaceUnsupported("cosmos")) {
            try builder.validate(required: required, selected: proposals(required: required))
        }
    }
}

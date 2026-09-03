import Testing
import WalletConnectSign
@testable import WalletCore

struct WCNNamespaceBuilderValidationTests {
    private let builder = WCNChainSupportFixtures.builder()
    private let account = WCNChainSupportFixtures.walletAccount

    private func candidates(required: [String: ProposalNamespace], optional: [String: ProposalNamespace]? = nil) -> [WCNChainCandidate] {
        builder.candidates(required: required, optional: optional, account: account)
    }

    @Test func optionalOnlyProposalAlwaysValidates() throws {
        let selected = candidates(required: [:], optional: WCNChainSupportFixtures.spikeOptional)
        try builder.validate(required: [:], selected: selected)
    }

    @Test func validRequiredSelectionPasses() throws {
        let required = ["eip155": WCNChainSupportFixtures.namespace(["eip155:1", "eip155:10"], methods: ["personal_sign"], events: ["chainChanged"])]
        try builder.validate(required: required, selected: candidates(required: required))
    }

    @Test func deselectedRequiredChainFails() {
        let required = ["eip155": WCNChainSupportFixtures.namespace(["eip155:1", "eip155:10"], methods: [], events: [])]
        let selected = candidates(required: required).filter { $0.chain.reference == "1" }

        #expect(throws: WCNNamespaceBuilder.ValidationError.requiredChainUnsupported("eip155:10")) {
            try builder.validate(required: required, selected: selected)
        }
    }

    @Test func unsupportedRequiredChainFails() {
        let required = ["eip155": WCNChainSupportFixtures.namespace(["eip155:1", "eip155:999"], methods: [], events: [])]

        #expect(throws: WCNNamespaceBuilder.ValidationError.requiredChainUnsupported("eip155:999")) {
            try builder.validate(required: required, selected: candidates(required: required))
        }
    }

    @Test func unsupportedRequiredMethodFails() {
        let required = ["eip155": WCNChainSupportFixtures.namespace(["eip155:1"], methods: ["eth_foo"], events: [])]

        #expect(throws: WCNNamespaceBuilder.ValidationError.requiredMethodUnsupported("eth_foo")) {
            try builder.validate(required: required, selected: candidates(required: required))
        }
    }

    @Test func unsupportedRequiredEventFails() {
        let required = ["eip155": WCNChainSupportFixtures.namespace(["eip155:1"], methods: [], events: ["disconnect"])]

        #expect(throws: WCNNamespaceBuilder.ValidationError.requiredEventUnsupported("disconnect")) {
            try builder.validate(required: required, selected: candidates(required: required))
        }
    }

    @Test func requiredNamespaceWithNothingSelectedFails() {
        let required = ["cosmos": WCNChainSupportFixtures.namespace(["cosmos:cosmoshub-4"], methods: [], events: [])]

        #expect(throws: WCNNamespaceBuilder.ValidationError.requiredNamespaceUnsupported("cosmos")) {
            try builder.validate(required: required, selected: candidates(required: required))
        }
    }
}

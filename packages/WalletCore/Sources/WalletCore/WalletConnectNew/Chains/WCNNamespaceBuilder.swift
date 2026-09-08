import WalletConnectSign
import WalletConnectUtils

class WCNNamespaceBuilder {
    private let registry: WCNChainSupportRegistry

    init(registry: WCNChainSupportRegistry) {
        self.registry = registry
    }

    func proposals(required: [String: ProposalNamespace], optional: [String: ProposalNamespace]?, account: Account) -> [WCNBlockchainProposal] {
        var proposals = [WCNBlockchainProposal]()

        for (key, namespace) in Self.sorted(required) {
            append(key: key, namespace: namespace, required: true, account: account, into: &proposals)
        }
        for (key, namespace) in Self.sorted(optional ?? [:]) {
            append(key: key, namespace: namespace, required: false, account: account, into: &proposals)
        }

        return proposals
    }

    func validate(required: [String: ProposalNamespace], selected: [WCNBlockchainProposal]) throws {
        for (key, namespace) in required {
            guard let namespaceName = Self.namespaceName(key: key) else {
                throw ValidationError.requiredNamespaceUnsupported(key)
            }
            let selectedInNamespace = selected.filter { $0.chain.namespace == namespaceName }

            guard !selectedInNamespace.isEmpty else {
                throw ValidationError.requiredNamespaceUnsupported(key)
            }

            for chain in Self.chains(key: key, namespace: namespace) where !selectedInNamespace.contains(where: { $0.chain == chain }) {
                throw ValidationError.requiredChainUnsupported(chain.absoluteString)
            }

            for method in namespace.methods where !selectedInNamespace.allSatisfy({ $0.methods.contains(method) }) {
                throw ValidationError.requiredMethodUnsupported(method)
            }

            for event in namespace.events where !selectedInNamespace.allSatisfy({ $0.events.contains(event) }) {
                throw ValidationError.requiredEventUnsupported(event)
            }
        }
    }

    func sessionNamespaces(selected: [WCNBlockchainProposal]) -> [String: SessionNamespace] {
        var result = [String: SessionNamespace]()

        for proposal in selected {
            let namespace = proposal.chain.namespace
            let existing = result[namespace]
            result[namespace] = SessionNamespace(
                accounts: (existing?.accounts ?? []) + [proposal.account],
                methods: (existing?.methods ?? []).union(proposal.methods),
                events: (existing?.events ?? []).union(proposal.events)
            )
        }

        return result
    }

    private func append(key: String, namespace: ProposalNamespace, required: Bool, account: Account, into proposals: inout [WCNBlockchainProposal]) {
        guard let namespaceName = Self.namespaceName(key: key), let support = registry.support(namespace: namespaceName) else {
            return
        }

        let supportedChains = support.supportedChains(account: account)
        let methods = namespace.methods.intersection(support.supportedMethods)
        let events = namespace.events.intersection(support.supportedEvents)

        for chain in Self.chains(key: key, namespace: namespace) where supportedChains.contains(chain) {
            if let index = proposals.firstIndex(where: { $0.chain == chain }) {
                proposals[index].methods.formUnion(methods)
                proposals[index].events.formUnion(events)
                proposals[index].required = proposals[index].required || required
                continue
            }

            guard let caipAccount = support.account(chain: chain, account: account) else {
                continue
            }

            proposals.append(WCNBlockchainProposal(chain: chain, account: caipAccount, methods: methods, events: events, required: required))
        }
    }

    // CAIP-25 allows chain-scoped keys ("eip155:1") with no `chains` field
    private static func chains(key: String, namespace: ProposalNamespace) -> [WalletConnectUtils.Blockchain] {
        if let chains = namespace.chains {
            return chains
        }
        return [WalletConnectUtils.Blockchain(key)].compactMap { $0 }
    }

    // a malformed optional-namespace key ("" or ":") must not crash: return nil and let callers skip it
    private static func namespaceName(key: String) -> String? {
        key.split(separator: ":", maxSplits: 1).first.map(String.init)
    }

    private static func sorted(_ namespaces: [String: ProposalNamespace]) -> [(String, ProposalNamespace)] {
        namespaces.sorted { $0.key < $1.key }
    }
}

extension WCNNamespaceBuilder {
    enum ValidationError: Error, Equatable {
        case requiredNamespaceUnsupported(String)
        case requiredChainUnsupported(String)
        case requiredMethodUnsupported(String)
        case requiredEventUnsupported(String)
    }
}

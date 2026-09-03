import WalletConnectSign
import WalletConnectUtils

class WCNNamespaceBuilder {
    private let registry: WCNChainSupportRegistry

    init(registry: WCNChainSupportRegistry) {
        self.registry = registry
    }

    func candidates(required: [String: ProposalNamespace], optional: [String: ProposalNamespace]?, account: Account) -> [WCNChainCandidate] {
        var candidates = [WCNChainCandidate]()

        for (key, namespace) in Self.sorted(required) {
            append(key: key, namespace: namespace, required: true, account: account, into: &candidates)
        }
        for (key, namespace) in Self.sorted(optional ?? [:]) {
            append(key: key, namespace: namespace, required: false, account: account, into: &candidates)
        }

        return candidates
    }

    func validate(required: [String: ProposalNamespace], selected: [WCNChainCandidate]) throws {
        for (key, namespace) in required {
            let namespaceName = Self.namespaceName(key: key)
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

    func sessionNamespaces(selected: [WCNChainCandidate]) -> [String: SessionNamespace] {
        var result = [String: SessionNamespace]()

        for candidate in selected {
            let namespace = candidate.chain.namespace
            let existing = result[namespace]
            result[namespace] = SessionNamespace(
                accounts: (existing?.accounts ?? []) + [candidate.account],
                methods: (existing?.methods ?? []).union(candidate.methods),
                events: (existing?.events ?? []).union(candidate.events)
            )
        }

        return result
    }

    private func append(key: String, namespace: ProposalNamespace, required: Bool, account: Account, into candidates: inout [WCNChainCandidate]) {
        guard let support = registry.support(namespace: Self.namespaceName(key: key)) else {
            return
        }

        let supportedChains = support.supportedChains(account: account)
        let methods = namespace.methods.intersection(support.supportedMethods)
        let events = namespace.events.intersection(support.supportedEvents)

        for chain in Self.chains(key: key, namespace: namespace) where supportedChains.contains(chain) {
            if let index = candidates.firstIndex(where: { $0.chain == chain }) {
                candidates[index].methods.formUnion(methods)
                candidates[index].events.formUnion(events)
                candidates[index].required = candidates[index].required || required
                continue
            }

            guard let caipAccount = support.account(chain: chain, account: account) else {
                continue
            }

            candidates.append(WCNChainCandidate(chain: chain, account: caipAccount, methods: methods, events: events, required: required))
        }
    }

    // CAIP-25 allows chain-scoped keys ("eip155:1") with no `chains` field
    private static func chains(key: String, namespace: ProposalNamespace) -> [WalletConnectUtils.Blockchain] {
        if let chains = namespace.chains {
            return chains
        }
        return [WalletConnectUtils.Blockchain(key)].compactMap { $0 }
    }

    private static func namespaceName(key: String) -> String {
        String(key.split(separator: ":", maxSplits: 1)[0])
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

import Foundation
import WalletConnectSign

protocol IProposalHandler {
    func handle(provider: INamespaceProvider) -> WalletConnectMainModule.BlockchainSet
}

protocol INamespaceProvider {
    func get(namespace: String) -> [ProposalNamespace]
}

extension Session.Proposal: INamespaceProvider {
    func get(namespace: String) -> [ProposalNamespace] {
        [requiredNamespaces[namespace], optionalNamespaces?[namespace]].compactMap { $0 }
    }
}

extension Session: INamespaceProvider {
    var proposalNamespaces: [String: ProposalNamespace] {
        namespaces.reduce(into: [:]) {
            $0[$1.key] = ProposalNamespace(
                chains: Set($1.value.accounts.compactMap { account in
                    Blockchain(namespace: account.namespace, reference: account.reference)
                }),
                methods: $1.value.methods,
                events: $1.value.events
            )
        }
    }

    func get(namespace: String) -> [ProposalNamespace] {
        [proposalNamespaces[namespace]]
            .compactMap { $0 }
    }
}

class ProposalChain {
    private var handlers = [IProposalHandler]()

    func append(handler: IProposalHandler) {
        handlers.append(handler)
    }
}

extension ProposalChain: IProposalHandler {
    func handle(provider: INamespaceProvider) -> WalletConnectMainModule.BlockchainSet {
        var set = WalletConnectMainModule.BlockchainSet.empty

        for handler in handlers {
            let result = handler.handle(provider: provider)

            set.formUnion(result)
        }

        return set
    }
}

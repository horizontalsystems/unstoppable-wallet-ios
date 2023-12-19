import Foundation
import WalletConnectSign

class ProposalValidator {
    func validate(namespaces: [String: ProposalNamespace], set: WalletConnectMainModule.BlockchainSet) throws {
        for (_, namespace) in namespaces {
            if let chains = namespace.chains {
                try chains.forEach { blockchain in
                    if !set.items.contains(where: { $0.equal(blockchain: blockchain) }) {
                        throw ValidateError.unsupportedReference(
                            namespace: blockchain.namespace,
                            reference: blockchain.reference
                        )
                    }
                }
            }

            try namespace.methods.forEach { method in
                if !set.methods.contains(method) {
                    throw ValidateError.unsupportedMethod(method)
                }
            }

            try namespace.events.forEach { event in
                if !set.events.contains(event) {
                    throw ValidateError.unsupportedEvent(event)
                }
            }
        }
    }
}

extension ProposalValidator {
    enum ValidateError: Error {
        case unsupportedReference(namespace: String, reference: String)
        case unsupportedMethod(String)
        case unsupportedEvent(String)
    }
}

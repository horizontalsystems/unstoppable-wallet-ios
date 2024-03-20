import Foundation
import WalletConnectSign

class ProposalValidator {
    func validate(namespaces: [String: ProposalNamespace], set: WalletConnectMainModule.BlockchainSet) throws {
        for (_, namespace) in namespaces {
            if let chains = namespace.chains {
                for blockchain in chains {
                    if !set.items.contains(where: { $0.equal(blockchain: blockchain) }) {
                        throw ValidateError.unsupportedReference(
                            namespace: blockchain.namespace,
                            reference: blockchain.reference
                        )
                    }
                }
            }

            for method in namespace.methods {
                if !set.methods.contains(method) {
                    throw ValidateError.unsupportedMethod(method)
                }
            }

            for event in namespace.events {
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

import Foundation
import WalletConnectSign

class ProposalValidator {
    func validate(namespaces: [String: ProposalNamespace], set: WalletConnectMainModule.BlockchainSet) throws {
        for (_, namespace) in namespaces {
            if let chains = namespace.chains {
                try chains.forEach { blockchain in
                    if !set.items.contains(where: { $0.equal(blockchain: blockchain) }) {
                        throw ValidateError.unsupported(
                            namespace: blockchain.namespace,
                            reference: blockchain.reference
                        )
                    }
                }
            }

            try namespace.methods.forEach { method in
                if !set.methods.contains(method) {
                    throw ValidateError.unsupported(method: method)
                }
            }

            try namespace.events.forEach { event in
                if !set.events.contains(event) {
                    throw ValidateError.unsupported(event: event)
                }
            }
        }
    }
}

extension ProposalValidator {
    enum ValidateError: Error {
        case unsupported(namespace: String, reference: String)
        case unsupported(method: String)
        case unsupported(event: String)
    }
}

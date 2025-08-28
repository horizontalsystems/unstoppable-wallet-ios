import Foundation
import WalletConnectSign

class ProposalValidator {
    static func separateByNamespace(blockchains: [WalletConnectMainModule.BlockchainProposal]) -> [String: [WalletConnectMainModule.BlockchainProposal]] {
        var namespaces = [String: [WalletConnectMainModule.BlockchainProposal]]()
        for blockchain in blockchains {
            if var namespace = namespaces[blockchain.item.namespace] {
                namespace.append(blockchain)
            } else {
                namespaces[blockchain.item.namespace] = [blockchain]
            }
        }

        return namespaces
    }

    static func convertToSessionNamespace(blockchains: [WalletConnectMainModule.BlockchainProposal]) -> SessionNamespace? {
        var accounts = [WalletConnectUtils.Account]()
        var methods = Set<String>()
        var events = Set<String>()

        for blockchain in blockchains {
            guard
                let chain = Blockchain(namespace: blockchain.item.namespace, reference: blockchain.item.chainId),
                let account = WalletConnectUtils.Account(blockchain: chain, address: blockchain.item.address)
            else {
                continue
            }

            accounts.append(account)
            methods.formUnion(blockchain.methods)
            events.formUnion(blockchain.events)
        }

        guard !accounts.isEmpty else {
            return nil
        }
        return .init(accounts: accounts, methods: methods, events: events)
    }

    static func validate(namespaces: [String: ProposalNamespace], blockchains: [WalletConnectMainModule.BlockchainProposal]) throws {
        for (namespace, proposalNamespace) in namespaces {
            let separated = separateByNamespace(blockchains: blockchains)
            guard let blockchains = separated[namespace] else {
                throw ValidateError.unsupportedReference(
                    namespace: namespace,
                    reference: "any"
                )
            }

            if let chains = proposalNamespace.chains {
                for blockchain in chains {
                    if !blockchains.contains(where: { $0.item.equal(blockchain: blockchain) }) {
                        throw ValidateError.unsupportedReference(
                            namespace: blockchain.namespace,
                            reference: blockchain.reference
                        )
                    }
                }
            }

            for method in proposalNamespace.methods {
                guard blockchains.allSatisfy({ $0.methods.contains(method) }) else {
                    throw ValidateError.unsupportedMethod(method)
                }
            }

            for event in proposalNamespace.events {
                guard blockchains.allSatisfy({ $0.events.contains(event) }) else {
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

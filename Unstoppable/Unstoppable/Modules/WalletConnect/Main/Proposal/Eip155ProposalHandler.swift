import Foundation
import WalletConnectSign

class Eip155ProposalHandler {
    static let namespace = "eip155"

    static let supportedEvents = [
        "connect",
        "disconnect",
        "message",
        "chainChanged",
        "accountsChanged",
    ]

    private let evmBlockchainManager: EvmBlockchainManager
    private let account: Account
    private let supportedMethods: [String]

    init(evmBlockchainManager: EvmBlockchainManager, account: Account, supportedMethods: [String]) {
        self.evmBlockchainManager = evmBlockchainManager
        self.account = account
        self.supportedMethods = supportedMethods
    }

    private func blockchains(namespace: ProposalNamespace) -> [WalletConnectMainModule.BlockchainProposal] {
        var items = [WalletConnectMainModule.BlockchainItem]()
        var methods = Set<String>()
        var events = Set<String>()

        for blockchain in namespace.chains ?? [] {
            guard blockchain.namespace == Eip155ProposalHandler.namespace,
                  let chainId = Int(blockchain.reference),
                  let evmBlockchain = evmBlockchainManager.blockchain(chainId: chainId)
            else {
                // can't get blockchain by chainId, or can't parse chainId
                continue
            }

            guard let address = try? AccountAddress.evmAddress(account: account, blockchainType: evmBlockchain.type)
            else {
                // can't get address for chain
                continue
            }

            items.append(
                WalletConnectMainModule.BlockchainItem(
                    namespace: blockchain.namespace,
                    chainId: blockchain.reference,
                    blockchain: evmBlockchain,
                    address: address.eip55
                )
            )
        }

        for method in namespace.methods {
            if supportedMethods.contains(method) {
                methods.insert(method)
            }
        }

        for event in namespace.events {
            if Self.supportedEvents.contains(event) {
                events.insert(event)
            }
        }

        return items.map { .init(item: $0, methods: methods, events: events) }
    }
}

extension Eip155ProposalHandler: IProposalHandler {
    func handle(provider: INamespaceProvider) -> [WalletConnectMainModule.BlockchainProposal] {
        var proposals = [WalletConnectMainModule.BlockchainProposal]()

        for namespace in provider.get(namespace: Self.namespace) {
            proposals.append(contentsOf: blockchains(namespace: namespace))
        }

        return proposals
    }
}

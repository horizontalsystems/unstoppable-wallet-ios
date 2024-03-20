import Foundation
import WalletConnectSign

class Eip155ProposalHandler {
    static let namespace = "eip155"

    static let supportedEvents = [
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

    private func blockchainSet(namespace: ProposalNamespace) -> WalletConnectMainModule.BlockchainSet {
        var set = WalletConnectMainModule.BlockchainSet.empty

        for blockchain in namespace.chains ?? [] {
            guard let chainId = Int(blockchain.reference),
                  let evmBlockchain = evmBlockchainManager.blockchain(chainId: chainId)
            else {
                // can't get blockchain by chainId, or can't parse chainId
                continue
            }

            let chain = evmBlockchainManager.chain(blockchainType: evmBlockchain.type)

            guard let address = try? WalletConnectManager.evmAddress(account: account, chain: chain) else {
                // can't get address for chain
                continue
            }

            set.items.insert(
                WalletConnectMainModule.BlockchainItem(
                    namespace: blockchain.namespace,
                    chainId: chainId,
                    blockchain: evmBlockchain,
                    address: address.eip55
                )
            )
        }

        for method in namespace.methods {
            if supportedMethods.contains(method) {
                set.methods.insert(method)
            }
        }

        for event in namespace.events {
            if Self.supportedEvents.contains(event) {
                set.events.insert(event)
            }
        }

        return set
    }
}

extension Eip155ProposalHandler: IProposalHandler {
    func handle(provider: INamespaceProvider) -> WalletConnectMainModule.BlockchainSet {
        var set = WalletConnectMainModule.BlockchainSet.empty

        for namespace in provider.get(namespace: Self.namespace) {
            set.formUnion(blockchainSet(namespace: namespace))
        }

        return set
    }
}

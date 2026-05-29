import Foundation
import StellarKit
import WalletConnectSign

class StellarProposalHandler {
    static let namespace = "stellar"
    private static let reference = "pubnet"

    static let supportedEvents = [
        "connect",
        "disconnect",
        "message",
    ]

    private let stellarKitManager: StellarKitManager
    private let account: Account
    private let supportedMethods: [String]

    init(stellarKitManager: StellarKitManager, account: Account, supportedMethods: [String]) {
        self.stellarKitManager = stellarKitManager
        self.account = account
        self.supportedMethods = supportedMethods
    }

    private func blockchains(namespace: ProposalNamespace) -> [WalletConnectMainModule.BlockchainProposal] {
        var items = [WalletConnectMainModule.BlockchainItem]()
        var methods = Set<String>()
        var events = Set<String>()

        for blockchain in namespace.chains ?? [] {
            guard
                blockchain.namespace == Self.namespace,
                blockchain.reference == Self.reference,
                let stellarBlockchain = stellarKitManager.blockchain
            else {
                // can't use another namespace
                continue
            }
            guard let address = try? WalletConnectManager.stellarAddress(account: account) else {
//                 can't get address for account
                continue
            }

            items.append(
                WalletConnectMainModule.BlockchainItem(
                    namespace: blockchain.namespace,
                    chainId: blockchain.reference,
                    blockchain: stellarBlockchain,
                    address: address
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

extension StellarProposalHandler: IProposalHandler {
    func handle(provider: INamespaceProvider) -> [WalletConnectMainModule.BlockchainProposal] {
        var proposals = [WalletConnectMainModule.BlockchainProposal]()

        for namespace in provider.get(namespace: Self.namespace) {
            proposals.append(contentsOf: blockchains(namespace: namespace))
        }

        return proposals
    }
}

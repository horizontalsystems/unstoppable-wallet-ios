import Foundation
import MarketKit
import WalletConnectSign
@testable import WalletCore

final class WCStubChainSupport: IWCChainSupport {
    let namespace: String
    let supportedMethods: [String]
    let supportedEvents: [String]
    private let chains: [WalletConnectUtils.Blockchain]
    private let address: String

    init(namespace: String, references: [String], address: String, methods: [String], events: [String]) {
        self.namespace = namespace
        chains = references.compactMap { WalletConnectUtils.Blockchain(namespace: namespace, reference: $0) }
        self.address = address
        supportedMethods = methods
        supportedEvents = events
    }

    func supportedChains(account _: WalletCore.Account) -> [WalletConnectUtils.Blockchain] {
        chains
    }

    func account(chain: WalletConnectUtils.Blockchain, account _: WalletCore.Account) -> WalletConnectUtils.Account? {
        guard chains.contains(chain) else { return nil }
        return try? WalletConnectUtils.Account(blockchain: chain, accountAddress: address)
    }

    func blockchainType(chain _: WalletConnectUtils.Blockchain) -> BlockchainType? {
        namespace == "eip155" ? .ethereum : nil
    }
}

enum WCChainSupportFixtures {
    static let stellarAddress = "GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H"

    static let walletAccount = WalletCore.Account(
        id: "account-1", level: 0, name: "Test",
        type: .mnemonic(words: Array(repeating: "abandon", count: 11) + ["about"], salt: "", bip39Compliant: true),
        origin: .restored, backedUp: true, fileBackedUp: false
    )

    static func evmSupport() -> WCStubChainSupport {
        WCStubChainSupport(
            namespace: "eip155", references: ["1", "10", "56"], address: WCTestFixtures.address,
            methods: ["eth_sendTransaction", "personal_sign", "eth_signTypedData_v4"],
            events: ["chainChanged", "accountsChanged"]
        )
    }

    static func stellarSupport() -> WCStubChainSupport {
        WCStubChainSupport(namespace: "stellar", references: ["pubnet"], address: stellarAddress, methods: ["stellar_signXDR"], events: ["message"])
    }

    static func builder(_ supports: [IWCChainSupport] = [evmSupport(), stellarSupport()]) -> WCNamespaceBuilder {
        let registry = WCChainSupportRegistry()
        supports.forEach { registry.register($0) }
        return WCNamespaceBuilder(registry: registry)
    }

    static func namespace(_ chains: [String]?, methods: [String], events: [String]) -> ProposalNamespace {
        ProposalNamespace(chains: chains.map { $0.compactMap { WalletConnectUtils.Blockchain($0) } }, methods: Set(methods), events: Set(events))
    }

    // exact proposal from the 2026-09-02 spike against react-app.walletconnect.com
    static let spikeOptional: [String: ProposalNamespace] = [
        "eip155": namespace(["eip155:1", "eip155:10"], methods: ["eth_sendTransaction", "personal_sign"], events: ["accountsChanged", "chainChanged"]),
    ]
}

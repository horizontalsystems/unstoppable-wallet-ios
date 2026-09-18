import Combine
import Foundation
import MarketKit
import XrpKit

/// Node selection for the XRP Ledger, in the `ZcashNodeManager` form minus the two parts XRP does
/// not have: no custom nodes and no auto-select. Android ships no node UI at all, so the screen
/// only reorders the kit's own failover list.
public class XrpNodeManager {
    private let blockchainSettingsStorage: BlockchainSettingsStorage

    // senders are user flows on the settings screen — effectively serialized
    private let nodeUpdatedSubject = PassthroughSubject<BlockchainType, Never>()

    public init(blockchainSettingsStorage: BlockchainSettingsStorage) {
        self.blockchainSettingsStorage = blockchainSettingsStorage
    }
}

extension XrpNodeManager {
    var nodeUpdatedPublisher: AnyPublisher<BlockchainType, Never> {
        nodeUpdatedSubject.eraseToAnyPublisher()
    }

    func allNodes(network: XrpKit.Network) -> [XrpNode] {
        XrpNode.defaultNodes(network: network)
    }

    /// The stored choice, or the kit's first node. A selection made on the other network simply
    /// does not match, so switching testnet on and off keeps both choices.
    func node(network: XrpKit.Network) -> XrpNode {
        let nodes = allNodes(network: network)

        if let urlString = blockchainSettingsStorage.xrpNodeUrl(blockchainType: .xrp),
           let node = nodes.first(where: { $0.url.absoluteString == urlString })
        {
            return node
        }

        return nodes[0]
    }

    func setCurrent(node: XrpNode, network _: XrpKit.Network) {
        blockchainSettingsStorage.save(xrpNodeUrl: node.url.absoluteString, blockchainType: .xrp)
        nodeUpdatedSubject.send(.xrp)
    }

    /// The chosen node leads the list the kit is given; the others stay behind it as fallbacks, so
    /// a node-local outage does not freeze the wallet (kit `RpcApiProvider` rotation).
    func rpcUrls(network: XrpKit.Network) -> [URL] {
        let selected = node(network: network).url
        return [selected] + network.rpcUrls.filter { $0 != selected }
    }
}

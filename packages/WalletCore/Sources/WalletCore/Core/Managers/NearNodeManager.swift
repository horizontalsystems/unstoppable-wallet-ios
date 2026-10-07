import Combine
import Foundation
import MarketKit
import NearKit

public class NearNodeManager {
    private let blockchainSettingsStorage: BlockchainSettingsStorage
    private let nodeUpdatedSubject = PassthroughSubject<BlockchainType, Never>()

    public init(blockchainSettingsStorage: BlockchainSettingsStorage) {
        self.blockchainSettingsStorage = blockchainSettingsStorage
    }
}

extension NearNodeManager {
    var nodeUpdatedPublisher: AnyPublisher<BlockchainType, Never> {
        nodeUpdatedSubject.eraseToAnyPublisher()
    }

    func allNodes(network: NearKit.Network) -> [NearNode] {
        NearNode.defaultNodes(network: network)
    }

    func node(network: NearKit.Network) -> NearNode {
        let nodes = allNodes(network: network)

        if let urlString = blockchainSettingsStorage.nearNodeUrl(blockchainType: .near, testNet: !network.isMainNet),
           let node = nodes.first(where: { $0.url.absoluteString == urlString })
        {
            return node
        }

        return nodes[0]
    }

    func setCurrent(node: NearNode, network: NearKit.Network) {
        blockchainSettingsStorage.save(nearNodeUrl: node.url.absoluteString, blockchainType: .near, testNet: !network.isMainNet)
        nodeUpdatedSubject.send(.near)
    }

    // the selected node leads, the others stay behind it as the kit's failover
    func rpcUrls(network: NearKit.Network) -> [URL] {
        let selected = node(network: network).url
        return [selected] + network.rpcUrls.filter { $0 != selected }
    }
}

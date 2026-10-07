import Foundation
import MarketKit
import NearKit

class NearNodeNetworkHandler: NodeNetworkHandlerProvider {
    override class func instance(blockchain: Blockchain) -> NodeNetworkHandlers? {
        guard blockchain.type == .near else {
            return nil
        }

        return NodeNetworkHandlers(
            nodeProvider: NearNodeNetworkHandler(blockchain: blockchain),
            autoSelectEngine: nil,
            updateSignalProvider: nil,
            customNodeHandler: nil
        )
    }

    private let blockchain: Blockchain
    private let nodeManager = Core.shared.nearNodeManager

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
        super.init()
    }

    private var network: NearKit.Network {
        NearKitManager.network
    }

    private func node(id: String) -> NearNode? {
        nodeManager.allNodes(network: network).first { $0.url.absoluteString == id }
    }
}

extension NearNodeNetworkHandler: INodeProvider {
    var currentNodeId: String {
        nodeManager.node(network: network).url.absoluteString
    }

    func nodes() -> (defaultNodes: [NodeNetworkItem], customNodes: [NodeNetworkItem]) {
        let items = nodeManager.allNodes(network: network).map {
            NodeNetworkItem(id: $0.url.absoluteString, name: $0.name, url: $0.url.absoluteString)
        }

        return (items, [])
    }

    func validate(id: String) async throws {
        guard let node = node(id: id) else { return }

        let result = await NearKit.NodePinger.ping(url: node.url, network: network)

        guard result.isValid else {
            throw ValidationError.unavailable
        }
    }

    func setCurrent(id: String) {
        guard let node = node(id: id) else { return }

        stat(page: .blockchainSettingsNear, event: .switchNearNode(chainUid: blockchain.uid, name: node.name))

        nodeManager.setCurrent(node: node, network: network)
    }

    func applyNode(id: String) {
        guard let node = node(id: id) else { return }
        nodeManager.setCurrent(node: node, network: network)
    }
}

extension NearNodeNetworkHandler {
    enum ValidationError: Error {
        case unavailable
    }
}

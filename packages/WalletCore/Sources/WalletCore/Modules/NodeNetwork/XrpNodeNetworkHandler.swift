import Foundation
import MarketKit
import XrpKit

// The shared node bundle with two slots left empty: no auto-select engine (no toggle, no pings)
// and no custom-node handler (no Added section, no Add New). Android has no XRP node UI at all,
// so the screen stays a pick from the kit's own list.
class XrpNodeNetworkHandler: NodeNetworkHandlerProvider {
    override class func instance(blockchain: Blockchain) -> NodeNetworkHandlers? {
        guard blockchain.type == .xrp else {
            return nil
        }

        return NodeNetworkHandlers(
            nodeProvider: XrpNodeNetworkHandler(blockchain: blockchain),
            autoSelectEngine: nil,
            updateSignalProvider: nil,
            customNodeHandler: nil
        )
    }

    private let blockchain: Blockchain
    private let nodeManager = Core.shared.xrpNodeManager

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
        super.init()
    }

    private var network: XrpKit.Network {
        XrpKitManager.network
    }

    private func node(id: String) -> XrpNode? {
        nodeManager.allNodes(network: network).first { $0.url.absoluteString == id }
    }
}

extension XrpNodeNetworkHandler: INodeProvider {
    var currentNodeId: String {
        nodeManager.node(network: network).url.absoluteString
    }

    func nodes() -> (defaultNodes: [NodeNetworkItem], customNodes: [NodeNetworkItem]) {
        let items = nodeManager.allNodes(network: network).map {
            NodeNetworkItem(id: $0.url.absoluteString, name: $0.name, url: $0.url.absoluteString)
        }

        return (items, [])
    }

    // One `server_state` round-trip: a node that is unreachable, behind, or on the other network
    // reverts the pick on the screen instead of leaving the wallet stuck on it.
    func validate(id: String) async throws {
        guard let node = node(id: id) else { return }

        let result = await NodePinger.ping(url: node.url, network: network)

        guard result.isValid else {
            throw ValidationError.unavailable
        }
    }

    func setCurrent(id: String) {
        guard let node = node(id: id) else { return }

        stat(page: .blockchainSettingsXrp, event: .switchXrpNode(chainUid: blockchain.uid, name: node.name))

        nodeManager.setCurrent(node: node, network: network)
    }

    func applyNode(id: String) {
        guard let node = node(id: id) else { return }
        nodeManager.setCurrent(node: node, network: network)
    }
}

extension XrpNodeNetworkHandler {
    enum ValidationError: Error {
        case unavailable
    }
}

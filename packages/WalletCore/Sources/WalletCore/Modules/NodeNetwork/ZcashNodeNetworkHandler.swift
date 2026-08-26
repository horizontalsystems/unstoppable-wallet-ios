import Combine
import Foundation
import MarketKit

// Single conformer serving all zcash slots of the bundle, like adapters conforming
// to several narrow protocols; the engine slot reuses the auto-select conformer.
class ZcashNodeNetworkHandler: NodeNetworkHandlerProvider {
    override class func instance(blockchain: Blockchain) -> NodeNetworkHandlers? {
        guard blockchain.type == .zcash else {
            return nil
        }

        let handler = ZcashNodeNetworkHandler(blockchain: blockchain)

        return NodeNetworkHandlers(
            nodeProvider: handler,
            autoSelectEngine: ZcashNodeAutoSelectEngine(
                nodeManager: Core.shared.zcashNodeManager,
                coinManager: Core.shared.coinManager,
                adapterManager: Core.shared.adapterManager
            ),
            updateSignalProvider: handler,
            customNodeHandler: handler
        )
    }

    private let blockchain: Blockchain
    private let nodeManager = Core.shared.zcashNodeManager

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
        super.init()
    }

    private func node(id: String) -> ZcashNode? {
        nodeManager.allNodes(blockchainType: blockchain.type).first { $0.url.absoluteString == id }
    }

    private func item(node: ZcashNode) -> NodeNetworkItem {
        NodeNetworkItem(id: node.url.absoluteString, name: node.name, url: node.url.absoluteString)
    }
}

extension ZcashNodeNetworkHandler: INodeProvider {
    var currentNodeId: String {
        nodeManager.node(blockchainType: blockchain.type).url.absoluteString
    }

    func nodes() -> (defaultNodes: [NodeNetworkItem], customNodes: [NodeNetworkItem]) {
        let (defaultNodes, customNodes) = nodeManager.defaultAndCustomNodes(blockchainType: blockchain.type)
        return (defaultNodes.map { item(node: $0) }, customNodes.map { item(node: $0) })
    }

    func validate(id: String) async throws {
        guard let node = node(id: id) else { return }
        try await Core.shared.adapterManager.validateZcashEndpoint(node.url)
    }

    func setCurrent(id: String) {
        guard let node = node(id: id) else { return }

        let isCustom = nodeManager.customNodes(blockchainType: blockchain.type).contains { $0.url == node.url }
        stat(page: .blockchainSettingsZcash, event: .switchZcashNode(chainUid: blockchain.uid, name: isCustom ? "custom" : node.name))

        nodeManager.setCurrent(node: node, blockchainType: blockchain.type)
    }

    func applyNode(id: String) {
        guard let node = node(id: id) else { return }
        nodeManager.setCurrent(node: node, blockchainType: blockchain.type)
    }
}

extension ZcashNodeNetworkHandler: IUpdateSignalProvider {
    var updateSignalPublisher: AnyPublisher<Void, Never> {
        nodeManager.nodesUpdatedPublisher
            .filter { [blockchain] in $0 == blockchain.type }
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}

extension ZcashNodeNetworkHandler: ICustomNodeHandler {
    func presentAddNode() {
        Coordinator.shared.present { [blockchain] isPresented in
            AddZcashNodeView(blockchainType: blockchain.type, isPresented: isPresented)
        }
        stat(page: .blockchainSettingsZcash, event: .openBlockchainSettingsZcashAdd(chainUid: blockchain.uid))
    }

    func removeNode(id: String) throws {
        guard let node = node(id: id) else { return }

        try nodeManager.delete(node: node, blockchainType: blockchain.type)
        stat(page: .blockchainSettingsZcash, event: .deleteCustomZcashNode(chainUid: blockchain.uid))
    }
}

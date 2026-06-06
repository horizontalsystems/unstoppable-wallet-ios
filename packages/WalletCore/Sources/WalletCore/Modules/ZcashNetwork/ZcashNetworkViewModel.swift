import Combine
import Foundation
import MarketKit
import RxSwift

class ZcashNetworkViewModel: ObservableObject {
    let blockchain: Blockchain
    private let zcashNodeManager = Core.shared.zcashNodeManager
    private var disposeBag = DisposeBag()

    @Published var defaultItems: [NodeItem] = []
    @Published var customItems: [NodeItem] = []
    @Published var saveEnabled = false

    private(set) var selectedNode: ZcashNode

    init(blockchain: Blockchain) {
        self.blockchain = blockchain

        selectedNode = zcashNodeManager.node(blockchainType: blockchain.type)

        subscribe(disposeBag, zcashNodeManager.nodesUpdatedObservable) { [weak self] _ in
            DispatchQueue.main.async { self?.handleNodesUpdated() }
        }

        syncItems()
    }

    private func handleNodesUpdated() {
        let (defaultNodes, customNodes) = zcashNodeManager.defaultAndCustomNodes(blockchainType: blockchain.type)
        let allNodes = defaultNodes + customNodes

        // If the locally selected node was deleted, reset selection to the manager's current
        if !allNodes.contains(where: { $0.url == selectedNode.url }) {
            selectedNode = zcashNodeManager.node(blockchainType: blockchain.type)
        }

        defaultItems = defaultNodes.map { nodeItem(node: $0) }
        customItems = customNodes.map { nodeItem(node: $0) }
        updateSaveEnabled()
    }

    private func syncItems() {
        let (defaultNodes, customNodes) = zcashNodeManager.defaultAndCustomNodes(blockchainType: blockchain.type)
        defaultItems = defaultNodes.map { nodeItem(node: $0) }
        customItems = customNodes.map { nodeItem(node: $0) }
    }

    private func nodeItem(node: ZcashNode) -> NodeItem {
        NodeItem(node: node, selected: node.url == selectedNode.url)
    }

    private func updateSaveEnabled() {
        let current = zcashNodeManager.node(blockchainType: blockchain.type)
        saveEnabled = selectedNode.url != current.url
    }
}

extension ZcashNetworkViewModel {
    func selectNode(_ item: NodeItem) {
        selectedNode = item.node

        let (defaultNodes, customNodes) = zcashNodeManager.defaultAndCustomNodes(blockchainType: blockchain.type)
        defaultItems = defaultNodes.map { nodeItem(node: $0) }
        customItems = customNodes.map { nodeItem(node: $0) }
        updateSaveEnabled()
    }

    func removeCustomNode(_ item: NodeItem) {
        stat(page: .blockchainSettingsZcash, event: .deleteCustomZcashNode(chainUid: blockchain.uid))
        zcashNodeManager.delete(node: item.node, blockchainType: blockchain.type)
    }

    func save() {
        let isCustom = customItems.contains { $0.node.url == selectedNode.url }
        stat(page: .blockchainSettingsZcash, event: .switchZcashNode(chainUid: blockchain.uid, name: isCustom ? "custom" : selectedNode.name))
        zcashNodeManager.setCurrent(node: selectedNode, blockchainType: blockchain.type)
    }
}

extension ZcashNetworkViewModel {
    struct NodeItem: Identifiable {
        let node: ZcashNode
        let selected: Bool

        var id: String { node.url.absoluteString }
        var name: String { node.name }
        var url: String { node.url.absoluteString }
    }
}

import Combine
import Foundation
import MarketKit
import MoneroKit
import RxSwift

class MoneroNetworkViewModel: ObservableObject {
    let blockchain: Blockchain
    private let moneroNodeManager = Core.shared.moneroNodeManager
    private var disposeBag = DisposeBag()

    @Published var defaultItems: [NodeItem] = []
    @Published var customItems: [NodeItem] = []
    @Published var saveEnabled = false

    private(set) var selectedNode: MoneroNode

    init(blockchain: Blockchain) {
        self.blockchain = blockchain

        selectedNode = moneroNodeManager.node(blockchainType: blockchain.type)

        subscribe(disposeBag, moneroNodeManager.nodesUpdatedObservable) { [weak self] _ in
            DispatchQueue.main.async { self?.handleNodesUpdated() }
        }

        syncItems()
    }

    private func handleNodesUpdated() {
        let (defaultNodes, customNodes) = moneroNodeManager.defaultAndCustomNodes(blockchainType: blockchain.type)
        let allNodes = defaultNodes + customNodes

        // If the locally selected node was deleted, reset selection to the manager's current
        if !allNodes.contains(where: { $0.node.url == selectedNode.node.url }) {
            selectedNode = moneroNodeManager.node(blockchainType: blockchain.type)
        }

        defaultItems = defaultNodes.map { nodeItem(node: $0) }
        customItems = customNodes.map { nodeItem(node: $0) }
        updateSaveEnabled()
    }

    private func syncItems() {
        let (defaultNodes, customNodes) = moneroNodeManager.defaultAndCustomNodes(blockchainType: blockchain.type)
        defaultItems = defaultNodes.map { nodeItem(node: $0) }
        customItems = customNodes.map { nodeItem(node: $0) }
    }

    private func nodeItem(node: MoneroNode) -> NodeItem {
        NodeItem(node: node, selected: node.node.url == selectedNode.node.url)
    }

    private func updateSaveEnabled() {
        let current = moneroNodeManager.node(blockchainType: blockchain.type)
        saveEnabled = selectedNode.node.url != current.node.url || selectedNode.node.isTrusted != current.node.isTrusted
    }
}

extension MoneroNetworkViewModel {
    func selectNode(_ item: NodeItem, isTrusted: Bool) {
        let kitNode = MoneroKit.Node(url: item.node.node.url, isTrusted: isTrusted, login: item.node.node.login, password: item.node.node.password)
        selectedNode = MoneroNode(name: item.node.name, node: kitNode)

        let (defaultNodes, customNodes) = moneroNodeManager.defaultAndCustomNodes(blockchainType: blockchain.type)
        defaultItems = defaultNodes.map { nodeItem(node: $0) }
        customItems = customNodes.map { nodeItem(node: $0) }
        updateSaveEnabled()
    }

    func removeCustomNode(_ item: NodeItem) {
        stat(page: .blockchainSettingsMonero, event: .deleteCustomMoneroNode(chainUid: blockchain.uid))
        moneroNodeManager.delete(node: item.node, blockchainType: blockchain.type)
    }

    func save() {
        let isCustom = customItems.contains { $0.node.node.url == selectedNode.node.url }
        stat(page: .blockchainSettingsMonero, event: .switchMoneroNode(chainUid: blockchain.uid, name: isCustom ? "custom" : selectedNode.name))
        moneroNodeManager.setCurrent(node: selectedNode, blockchainType: blockchain.type)
    }
}

extension MoneroNetworkViewModel {
    struct NodeItem: Identifiable {
        let node: MoneroNode
        let selected: Bool

        var id: String { node.node.url.absoluteString }
        var name: String { node.name }
        var url: String { node.node.url.absoluteString }
        var isTrusted: Bool { node.node.isTrusted }
    }
}

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

    private(set) var selectedNodeUrl: URL
    private(set) var selectedIsTrusted: Bool

    init(blockchain: Blockchain) {
        self.blockchain = blockchain

        let current = moneroNodeManager.node(blockchainType: blockchain.type)
        selectedNodeUrl = current.node.url
        selectedIsTrusted = current.node.isTrusted

        subscribe(disposeBag, moneroNodeManager.nodesUpdatedObservable) { [weak self] _ in
            DispatchQueue.main.async { self?.handleNodesUpdated() }
        }

        syncItems()
    }

    private func handleNodesUpdated() {
        let (defaultNodes, customNodes) = moneroNodeManager.defaultAndCustomNodes(blockchainType: blockchain.type)
        let allNodes = defaultNodes + customNodes

        // If the locally selected node was deleted, reset selection to the manager's current
        if !allNodes.contains(where: { $0.node.url == selectedNodeUrl }) {
            let current = moneroNodeManager.node(blockchainType: blockchain.type)
            selectedNodeUrl = current.node.url
            selectedIsTrusted = current.node.isTrusted
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
        NodeItem(node: node, selected: node.node.url == selectedNodeUrl)
    }

    private func updateSaveEnabled() {
        let current = moneroNodeManager.node(blockchainType: blockchain.type)
        saveEnabled = selectedNodeUrl != current.node.url || selectedIsTrusted != current.node.isTrusted
    }
}

extension MoneroNetworkViewModel {
    func selectNode(_ item: NodeItem, isTrusted: Bool) {
        selectedNodeUrl = item.node.node.url
        selectedIsTrusted = isTrusted

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
        guard let node = moneroNodeManager.allNodes(blockchainType: blockchain.type)
            .first(where: { $0.node.url == selectedNodeUrl }) else { return }

        let isCustom = customItems.contains { $0.node.node.url == selectedNodeUrl }
        stat(page: .blockchainSettingsMonero, event: .switchMoneroNode(chainUid: blockchain.uid, name: isCustom ? "custom" : node.name))

        let kitNode = MoneroKit.Node(url: node.node.url, isTrusted: selectedIsTrusted, login: node.node.login, password: node.node.password)
        let updatedNode = MoneroNode(name: node.name, node: kitNode)
        moneroNodeManager.setCurrent(node: updatedNode, blockchainType: blockchain.type)
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

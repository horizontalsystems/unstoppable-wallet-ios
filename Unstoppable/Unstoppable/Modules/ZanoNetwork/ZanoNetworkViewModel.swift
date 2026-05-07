import Combine
import Foundation
import MarketKit
import RxSwift

class ZanoNetworkViewModel: ObservableObject {
    let blockchain: Blockchain
    private let zanoNodeManager = Core.shared.zanoNodeManager
    private var disposeBag = DisposeBag()

    @Published var defaultItems: [NodeItem] = []
    @Published var customItems: [NodeItem] = []
    @Published var saveEnabled = false

    private(set) var selectedNodeUrl: URL

    init(blockchain: Blockchain) {
        self.blockchain = blockchain

        selectedNodeUrl = zanoNodeManager.node(blockchainType: blockchain.type).url

        subscribe(disposeBag, zanoNodeManager.nodesUpdatedObservable) { [weak self] _ in
            DispatchQueue.main.async { self?.handleNodesUpdated() }
        }

        syncItems()
    }

    private func handleNodesUpdated() {
        let (defaultNodes, customNodes) = zanoNodeManager.defaultAndCustomNodes(blockchainType: blockchain.type)
        let allNodes = defaultNodes + customNodes

        if !allNodes.contains(where: { $0.url == selectedNodeUrl }) {
            selectedNodeUrl = zanoNodeManager.node(blockchainType: blockchain.type).url
        }

        defaultItems = defaultNodes.map { nodeItem(node: $0) }
        customItems = customNodes.map { nodeItem(node: $0) }
        updateSaveEnabled()
    }

    private func syncItems() {
        let (defaultNodes, customNodes) = zanoNodeManager.defaultAndCustomNodes(blockchainType: blockchain.type)
        defaultItems = defaultNodes.map { nodeItem(node: $0) }
        customItems = customNodes.map { nodeItem(node: $0) }
    }

    private func nodeItem(node: ZanoNode) -> NodeItem {
        NodeItem(node: node, selected: node.url == selectedNodeUrl)
    }

    private func updateSaveEnabled() {
        let current = zanoNodeManager.node(blockchainType: blockchain.type)
        saveEnabled = selectedNodeUrl != current.url
    }
}

extension ZanoNetworkViewModel {
    func selectNode(_ item: NodeItem) {
        selectedNodeUrl = item.node.url

        let (defaultNodes, customNodes) = zanoNodeManager.defaultAndCustomNodes(blockchainType: blockchain.type)
        defaultItems = defaultNodes.map { nodeItem(node: $0) }
        customItems = customNodes.map { nodeItem(node: $0) }
        updateSaveEnabled()
    }

    func removeCustomNode(_ item: NodeItem) {
        stat(page: .blockchainSettingsZano, event: .deleteCustomZanoNode(chainUid: blockchain.uid))
        zanoNodeManager.delete(node: item.node, blockchainType: blockchain.type)
    }

    func save() {
        guard let node = zanoNodeManager.allNodes(blockchainType: blockchain.type)
            .first(where: { $0.url == selectedNodeUrl }) else { return }

        let isCustom = customItems.contains { $0.node.url == selectedNodeUrl }
        stat(page: .blockchainSettingsZano, event: .switchZanoNode(chainUid: blockchain.uid, name: isCustom ? "custom" : node.name))

        zanoNodeManager.setCurrent(node: node, blockchainType: blockchain.type)
    }
}

extension ZanoNetworkViewModel {
    struct NodeItem: Identifiable {
        let node: ZanoNode
        let selected: Bool

        var id: String { node.url.absoluteString }
        var name: String { node.name }
        var url: String { node.url.absoluteString }
    }
}

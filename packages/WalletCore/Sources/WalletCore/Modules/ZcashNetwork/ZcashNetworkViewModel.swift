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
    @Published var processing = false

    private let errorSubject = PassthroughSubject<String, Never>()

    private(set) var selectedNode: ZcashNode
    private var appliedNode: ZcashNode

    init(blockchain: Blockchain) {
        self.blockchain = blockchain

        selectedNode = zcashNodeManager.node(blockchainType: blockchain.type)
        appliedNode = selectedNode

        subscribe(disposeBag, zcashNodeManager.nodesUpdatedObservable) { [weak self] blockchainType in
            guard let self, blockchainType == self.blockchain.type else { return }
            DispatchQueue.main.async { [weak self] in self?.handleNodesUpdated() }
        }

        syncItems()
    }

    private func handleNodesUpdated() {
        let (defaultNodes, customNodes) = zcashNodeManager.defaultAndCustomNodes(blockchainType: blockchain.type)
        let allNodes = defaultNodes + customNodes

        // If the locally selected node was deleted, reset selection to the manager's current
        if !allNodes.contains(where: { $0.url == selectedNode.url }) {
            selectedNode = zcashNodeManager.node(blockchainType: blockchain.type)
            appliedNode = selectedNode
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
    var errorPublisher: AnyPublisher<String, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    func selectNode(_ item: NodeItem) {
        guard !processing else {
            return
        }

        let previousAppliedNode = appliedNode
        selectedNode = item.node

        let (defaultNodes, customNodes) = zcashNodeManager.defaultAndCustomNodes(blockchainType: blockchain.type)
        defaultItems = defaultNodes.map { nodeItem(node: $0) }
        customItems = customNodes.map { nodeItem(node: $0) }
        updateSaveEnabled()

        guard item.node.url != previousAppliedNode.url else {
            return
        }

        processing = true

        Task { [weak self] in
            do {
                try await Core.shared.adapterManager.validateZcashEndpoint(item.node.url)
                await self?.handleNodeValidationSuccess(node: item.node)
            } catch {
                await self?.handleNodeValidationFailure(node: previousAppliedNode)
            }
        }
    }

    func removeCustomNode(_ item: NodeItem) {
        do {
            try zcashNodeManager.delete(node: item.node, blockchainType: blockchain.type)
            stat(page: .blockchainSettingsZcash, event: .deleteCustomZcashNode(chainUid: blockchain.uid))
        } catch {
            HudHelper.instance.show(banner: .error(string: error.localizedDescription))
        }
    }

    func save() {
        guard !processing else {
            return
        }

        let isCustom = customItems.contains { $0.node.url == selectedNode.url }
        stat(page: .blockchainSettingsZcash, event: .switchZcashNode(chainUid: blockchain.uid, name: isCustom ? "custom" : selectedNode.name))
        zcashNodeManager.setCurrent(node: selectedNode, blockchainType: blockchain.type)
    }

    @MainActor
    private func handleNodeValidationSuccess(node: ZcashNode) {
        processing = false
        appliedNode = node
        updateSaveEnabled()
    }

    @MainActor
    private func handleNodeValidationFailure(node: ZcashNode) {
        processing = false
        selectedNode = node
        syncItems()
        updateSaveEnabled()
        errorSubject.send("sync_error".localized)
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

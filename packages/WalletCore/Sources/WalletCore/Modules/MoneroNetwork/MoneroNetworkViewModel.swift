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
    @Published var pingStates: [String: PingState] = [:]

    @Published var autoSelectEnabled: Bool {
        didSet {
            guard autoSelectEnabled != moneroNodeManager.autoSelectEnabled else { return }

            moneroNodeManager.autoSelectEnabled = autoSelectEnabled

            if autoSelectEnabled {
                applyFastestNode(results: lastPingResults)
            }
        }
    }

    private var lastPingResults: [NodePingResult] = []
    private var pingTask: Task<Void, Never>?

    private(set) var selectedNode: MoneroNode

    init(blockchain: Blockchain) {
        self.blockchain = blockchain

        selectedNode = moneroNodeManager.node(blockchainType: blockchain.type)
        autoSelectEnabled = moneroNodeManager.autoSelectEnabled

        subscribe(disposeBag, moneroNodeManager.nodesUpdatedObservable) { [weak self] blockchainType in
            guard let self, blockchainType == self.blockchain.type else { return }
            DispatchQueue.main.async { [weak self] in
                self?.handleNodesUpdated()
                self?.refreshPings()
            }
        }

        syncItems()
        refreshPings()
    }

    deinit {
        pingTask?.cancel()
    }

    func refreshPings() {
        pingTask?.cancel()

        for node in moneroNodeManager.allNodes(blockchainType: blockchain.type) {
            pingStates[node.node.url.absoluteString] = .loading
        }

        let blockchainType = blockchain.type
        pingTask = Task { [weak self, moneroNodeManager] in
            let results = await moneroNodeManager.pingNodes(blockchainType: blockchainType)

            guard !Task.isCancelled else { return }

            await MainActor.run { [weak self] in
                guard let self else { return }

                for result in results {
                    pingStates[result.node.url.absoluteString] = PingState(result: result)
                }

                lastPingResults = results

                if autoSelectEnabled {
                    applyFastestNode(results: results)
                }
            }
        }
    }

    // Auto-select applies immediately (with the manager's height-lag and hysteresis rules);
    // fires the node relay, so a running wallet reconnects to the winner.
    private func applyFastestNode(results: [NodePingResult]) {
        guard !results.isEmpty else { return }

        guard let fastest = moneroNodeManager.fastestNode(results: results, blockchainType: blockchain.type) else { return }

        moneroNodeManager.setCurrent(node: fastest, blockchainType: blockchain.type)
        selectedNode = fastest
        handleNodesUpdated()
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
    enum PingState {
        case loading
        case unreachable
        case reachable(text: String, level: Level)

        enum Level {
            case good, medium, slow
        }

        init(result: NodePingResult) {
            guard let responseTime = result.responseTime, result.isValid else {
                self = .unreachable
                return
            }

            let level: Level
            if responseTime <= NodePingResult.pingGood {
                level = .good
            } else if responseTime <= NodePingResult.pingMedium {
                level = .medium
            } else {
                level = .slow
            }

            self = .reachable(text: "\(Int(responseTime * 1000)) ms", level: level)
        }
    }

    struct NodeItem: Identifiable {
        let node: MoneroNode
        let selected: Bool

        var id: String { node.node.url.absoluteString }
        var name: String { node.name }
        var url: String { node.node.url.absoluteString }
        var isTrusted: Bool { node.node.isTrusted }
    }
}

import Combine
import Foundation
import MarketKit

class ZcashNetworkViewModel: ObservableObject {
    let blockchain: Blockchain
    private let zcashNodeManager = Core.shared.zcashNodeManager
    private var cancellables = Set<AnyCancellable>()

    @Published var defaultItems: [NodeItem] = []
    @Published var customItems: [NodeItem] = []
    @Published var saveEnabled = false
    @Published var processing = false
    @Published var pingStates: [String: PingState] = [:]

    // Draft state, like the node selection: nothing is persisted or applied until save().
    @Published var autoSelectEnabled: Bool {
        didSet {
            updateSaveEnabled()
        }
    }

    private let errorSubject = PassthroughSubject<String, Never>()

    private(set) var selectedNode: ZcashNode
    private var appliedNode: ZcashNode

    private var lastPings: [ZcashNodeManager.NodePing] = []
    private var pingTask: Task<Void, Never>?

    init(blockchain: Blockchain) {
        self.blockchain = blockchain

        selectedNode = zcashNodeManager.node(blockchainType: blockchain.type)
        appliedNode = selectedNode
        autoSelectEnabled = zcashNodeManager.autoSelectEnabled

        zcashNodeManager.nodesUpdatedPublisher
            .filter { [blockchain] in $0 == blockchain.type }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleNodesUpdated()
                self?.refreshPings()
            }
            .store(in: &cancellables)

        syncItems()
        refreshPings()
    }

    deinit {
        pingTask?.cancel()
    }

    func refreshPings() {
        pingTask?.cancel()

        for node in zcashNodeManager.allNodes(blockchainType: blockchain.type) {
            pingStates[node.url.absoluteString] = .loading
        }

        let blockchainType = blockchain.type
        pingTask = Task { [weak self, zcashNodeManager] in
            let pings = await zcashNodeManager.pingNodes(blockchainType: blockchainType)

            guard !Task.isCancelled else { return }

            await MainActor.run { [weak self] in
                guard let self else { return }

                for ping in pings {
                    pingStates[ping.node.url.absoluteString] = PingState(responseTime: ping.responseTime)
                }

                lastPings = pings

                // Persisted setting, not the draft toggle: refresh only re-applies a choice
                // the user has already saved.
                if zcashNodeManager.autoSelectEnabled {
                    applyFastestNode(pings: pings)
                }
            }
        }
    }

    // Applies via setCurrent → nodeRelay: AdapterManager switches the live adapter and
    // reverts the stored selection if the switch fails.
    private func applyFastestNode(pings: [ZcashNodeManager.NodePing]) {
        guard !pings.isEmpty else { return }

        let currentId = zcashNodeManager.node(blockchainType: blockchain.type).url.absoluteString
        let candidates = ZcashNodeManager.candidates(from: pings)

        guard let fastestId = NodeAutoSelector.fastestNodeId(results: candidates, currentId: currentId),
              let fastest = zcashNodeManager.allNodes(blockchainType: blockchain.type).first(where: { $0.url.absoluteString == fastestId })
        else { return }

        zcashNodeManager.setCurrent(node: fastest, blockchainType: blockchain.type)
        selectedNode = fastest
        appliedNode = fastest
        handleNodesUpdated()
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
        saveEnabled = selectedNode.url != current.url || autoSelectEnabled != zcashNodeManager.autoSelectEnabled
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

        zcashNodeManager.autoSelectEnabled = autoSelectEnabled

        if autoSelectEnabled {
            // Auto-select owns the node choice from now on; a manual pick made before the
            // toggle was flipped is superseded by the fastest-node result.
            applyFastestNode(pings: lastPings)
        } else if selectedNode.url != zcashNodeManager.node(blockchainType: blockchain.type).url {
            let isCustom = customItems.contains { $0.node.url == selectedNode.url }
            stat(page: .blockchainSettingsZcash, event: .switchZcashNode(chainUid: blockchain.uid, name: isCustom ? "custom" : selectedNode.name))
            zcashNodeManager.setCurrent(node: selectedNode, blockchainType: blockchain.type)
        }
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

    enum PingState {
        // UI coloring thresholds, matching the Monero badge levels
        static let pingGood: TimeInterval = 0.333
        static let pingMedium: TimeInterval = 0.667

        case loading
        case unreachable
        case reachable(text: String, level: Level)

        enum Level {
            case good, medium, slow
        }

        init(responseTime: TimeInterval?) {
            guard let responseTime else {
                self = .unreachable
                return
            }

            let level: Level
            if responseTime <= Self.pingGood {
                level = .good
            } else if responseTime <= Self.pingMedium {
                level = .medium
            } else {
                level = .slow
            }

            self = .reachable(text: "\(Int(responseTime * 1000)) ms", level: level)
        }
    }
}

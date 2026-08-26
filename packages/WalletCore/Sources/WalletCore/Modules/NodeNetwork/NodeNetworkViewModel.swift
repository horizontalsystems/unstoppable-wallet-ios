import Combine
import Foundation
import MarketKit

class NodeNetworkViewModel: ObservableObject {
    let blockchain: Blockchain
    private let nodeProvider: INodeProvider?
    private let autoSelectEngine: INodeAutoSelectEngine?
    // Retained: a signal provider distinct from the node provider would deallocate otherwise
    private let updateSignalProvider: IUpdateSignalProvider?
    private let customNodeHandler: ICustomNodeHandler?
    private var cancellables = Set<AnyCancellable>()

    @Published var defaultItems: [NodeItem] = []
    @Published var customItems: [NodeItem] = []
    @Published var saveEnabled = false
    @Published var processing = false
    @Published var pingStates: [String: PingState] = [:]
    // Blocks Save while auto-select is drafted ON and there is no probe result to apply yet
    @Published var pingsInFlight = false

    // Draft state, like the node selection: nothing is persisted or applied until save().
    @Published var autoSelectEnabled: Bool {
        didSet {
            updateSaveEnabled()
        }
    }

    private let errorSubject = PassthroughSubject<String, Never>()

    private(set) var selectedNodeId: String
    private var appliedNodeId: String

    private var lastPings: [NodeAutoSelector.PingResult] = []
    private var pingTask: Task<Void, Never>?

    init(blockchain: Blockchain) {
        self.blockchain = blockchain

        let handlers = NodeNetworkHandlerFactory.handlers(blockchain: blockchain)
        nodeProvider = handlers?.nodeProvider
        autoSelectEngine = handlers?.autoSelectEngine
        updateSignalProvider = handlers?.updateSignalProvider
        customNodeHandler = handlers?.customNodeHandler

        selectedNodeId = handlers?.nodeProvider.currentNodeId ?? ""
        appliedNodeId = selectedNodeId
        autoSelectEnabled = handlers?.autoSelectEngine?.autoSelectEnabled ?? false

        updateSignalProvider?.updateSignalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
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

    var autoSelectAvailable: Bool {
        autoSelectEngine != nil
    }

    var addNodeAvailable: Bool {
        customNodeHandler != nil
    }

    func refreshPings() {
        guard let nodeProvider, let autoSelectEngine else { return }

        pingTask?.cancel()
        pingsInFlight = true

        let (defaultNodes, customNodes) = nodeProvider.nodes()
        for node in defaultNodes + customNodes {
            pingStates[node.id] = .loading
        }

        pingTask = Task { [weak self, autoSelectEngine] in
            let pings = await autoSelectEngine.pingNodes()

            guard !Task.isCancelled else { return }

            await MainActor.run { [weak self] in
                guard let self else { return }

                for ping in pings {
                    pingStates[ping.id] = PingState(responseTime: ping.responseTime)
                }

                lastPings = pings
                pingsInFlight = false

                // Persisted setting, not the draft toggle: refresh only re-applies a choice
                // the user has already saved.
                if autoSelectEngine.autoSelectEnabled {
                    applyFastestNode(pings: pings)
                }
            }
        }
    }

    // Applies via applyNode → node manager relay: AdapterManager switches the live adapter
    // and reverts the stored selection if the switch fails.
    private func applyFastestNode(pings: [NodeAutoSelector.PingResult]) {
        guard let nodeProvider, !pings.isEmpty else { return }

        guard let fastestId = NodeAutoSelector.fastestNodeId(results: pings, currentId: nodeProvider.currentNodeId) else { return }

        nodeProvider.applyNode(id: fastestId)
        selectedNodeId = fastestId
        appliedNodeId = fastestId
        handleNodesUpdated()
    }

    private func handleNodesUpdated() {
        guard let nodeProvider else { return }

        let (defaultNodes, customNodes) = nodeProvider.nodes()

        // If the locally selected node was deleted, reset selection to the provider's current
        if !(defaultNodes + customNodes).contains(where: { $0.id == selectedNodeId }) {
            selectedNodeId = nodeProvider.currentNodeId
            appliedNodeId = selectedNodeId
        }

        defaultItems = defaultNodes.map { nodeItem(item: $0) }
        customItems = customNodes.map { nodeItem(item: $0) }
        updateSaveEnabled()
    }

    private func syncItems() {
        guard let nodeProvider else { return }

        let (defaultNodes, customNodes) = nodeProvider.nodes()
        defaultItems = defaultNodes.map { nodeItem(item: $0) }
        customItems = customNodes.map { nodeItem(item: $0) }
    }

    private func nodeItem(item: NodeNetworkItem) -> NodeItem {
        NodeItem(item: item, selected: item.id == selectedNodeId)
    }

    private func updateSaveEnabled() {
        guard let nodeProvider else { return }

        let toggleModified = autoSelectEngine.map { autoSelectEnabled != $0.autoSelectEnabled } ?? false
        saveEnabled = selectedNodeId != nodeProvider.currentNodeId || toggleModified
    }
}

extension NodeNetworkViewModel {
    var errorPublisher: AnyPublisher<String, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    func selectNode(_ item: NodeItem) {
        guard let nodeProvider, !processing else {
            return
        }

        let previousAppliedNodeId = appliedNodeId
        selectedNodeId = item.id

        syncItems()
        updateSaveEnabled()

        guard item.id != previousAppliedNodeId else {
            return
        }

        processing = true

        Task { [weak self, nodeProvider] in
            do {
                try await nodeProvider.validate(id: item.id)
                await self?.handleNodeValidationSuccess(id: item.id)
            } catch {
                await self?.handleNodeValidationFailure(id: previousAppliedNodeId)
            }
        }
    }

    func removeCustomNode(_ item: NodeItem) {
        do {
            try customNodeHandler?.removeNode(id: item.id)
        } catch {
            HudHelper.instance.show(banner: .error(string: error.localizedDescription))
        }
    }

    func addNode() {
        customNodeHandler?.presentAddNode()
    }

    func save() {
        guard let nodeProvider, !processing else {
            return
        }

        autoSelectEngine?.autoSelectEnabled = autoSelectEnabled

        if autoSelectEnabled {
            // Auto-select owns the node choice from now on; a manual pick made before the
            // toggle was flipped is superseded by the fastest-node result.
            applyFastestNode(pings: lastPings)
        } else if selectedNodeId != nodeProvider.currentNodeId {
            nodeProvider.setCurrent(id: selectedNodeId)
        }
    }

    @MainActor
    private func handleNodeValidationSuccess(id: String) {
        processing = false
        appliedNodeId = id
        updateSaveEnabled()
    }

    @MainActor
    private func handleNodeValidationFailure(id: String) {
        processing = false
        selectedNodeId = id
        syncItems()
        updateSaveEnabled()
        errorSubject.send("sync_error".localized)
    }
}

extension NodeNetworkViewModel {
    struct NodeItem: Identifiable {
        let item: NodeNetworkItem
        let selected: Bool

        var id: String { item.id }
        var name: String { item.name }
        var url: String { item.url }
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

import Combine
import Foundation
import MarketKit
import ZcashLightClientKit

public class ZcashNodeManager {
    private let testNetManager: TestNetManager
    private let blockchainSettingsStorage: BlockchainSettingsStorage
    private let zcashNodeStorage: ZcashNodeStorage

    // senders are user/restore flows — effectively serialized, honoring the send() contract
    private let nodeUpdatedSubject = PassthroughSubject<BlockchainType, Never>()
    private let nodesUpdatedSubject = PassthroughSubject<BlockchainType, Never>()

    public init(testNetManager: TestNetManager, blockchainSettingsStorage: BlockchainSettingsStorage, zcashNodeStorage: ZcashNodeStorage) {
        self.testNetManager = testNetManager
        self.blockchainSettingsStorage = blockchainSettingsStorage
        self.zcashNodeStorage = zcashNodeStorage
    }

    private func saveCurrent(nodeUrl: URL, blockchainType: BlockchainType) {
        blockchainSettingsStorage.save(zcashNodeUrl: nodeUrl.absoluteString, blockchainType: blockchainType)
        nodeUpdatedSubject.send(blockchainType)
    }

    private func defaultNodes(blockchainType: BlockchainType) -> [ZcashNode] {
        switch blockchainType {
        case .zcash:
            return testNetManager.testNetEnabled ? ZcashNode.defaultTestnetNodes : ZcashNode.defaultNodes
        default:
            return []
        }
    }
}

extension ZcashNodeManager {
    var nodeUpdatedPublisher: AnyPublisher<BlockchainType, Never> {
        nodeUpdatedSubject.eraseToAnyPublisher()
    }

    var nodesUpdatedPublisher: AnyPublisher<BlockchainType, Never> {
        nodesUpdatedSubject.eraseToAnyPublisher()
    }

    func customNodes(blockchainType: BlockchainType) -> [ZcashNode] {
        do {
            let records = try zcashNodeStorage.records(blockchainTypeUid: blockchainType.uid)
            return records.compactMap { record in
                guard let parsed = URLComponents(string: record.url),
                      let scheme = parsed.scheme?.lowercased(), [ /* "http", */ "https"].contains(scheme), // disable http:
                      let host = parsed.host?.lowercased(), !host.isEmpty,
                      parsed.user == nil, parsed.password == nil,
                      parsed.path.isEmpty || parsed.path == "/",
                      parsed.query == nil, parsed.fragment == nil
                else {
                    return nil
                }
                let port = parsed.port ?? 443
                guard (1 ... 65535).contains(port) else {
                    return nil
                }

                var components = URLComponents()
                components.scheme = scheme
                components.host = host
                components.port = port

                guard let url = components.url else {
                    return nil
                }

                return ZcashNode(name: host, url: url)
            }
        } catch {
            return []
        }
    }

    func defaultAndCustomNodes(blockchainType: BlockchainType) -> ([ZcashNode], [ZcashNode]) {
        let defaultNodes = defaultNodes(blockchainType: blockchainType)
        let customNodes = customNodes(blockchainType: blockchainType)

        let filteredCustom = customNodes.filter { custom in
            !defaultNodes.contains(where: { $0.url.absoluteString == custom.url.absoluteString })
        }

        return (defaultNodes, filteredCustom)
    }

    func allNodes(blockchainType: BlockchainType) -> [ZcashNode] {
        let (defaultNodes, customNodes) = defaultAndCustomNodes(blockchainType: blockchainType)
        return defaultNodes + customNodes
    }

    func node(blockchainType: BlockchainType) -> ZcashNode {
        let nodes = allNodes(blockchainType: blockchainType)

        if let urlString = blockchainSettingsStorage.zcashNodeUrl(blockchainType: blockchainType),
           let node = nodes.first(where: { $0.url.absoluteString == urlString })
        {
            return node
        }

        return nodes[0]
    }

    func setCurrent(node: ZcashNode, blockchainType: BlockchainType) {
        saveCurrent(nodeUrl: node.url, blockchainType: blockchainType)
    }

    func addNew(blockchainType: BlockchainType, url: URL) throws {
        let record = ZcashNodeRecord(blockchainTypeUid: blockchainType.uid, url: url.absoluteString)
        try zcashNodeStorage.save(record: record)

        nodesUpdatedSubject.send(blockchainType)
    }

    func delete(node: ZcashNode, blockchainType: BlockchainType) throws {
        let isCurrent = self.node(blockchainType: blockchainType) == node
        try zcashNodeStorage.delete(blockchainTypeUid: blockchainType.uid, url: node.url.absoluteString)

        if isCurrent {
            nodeUpdatedSubject.send(blockchainType)
        }

        nodesUpdatedSubject.send(blockchainType)
    }
}

extension ZcashNodeManager {
    // Self-reported estimate this far above served blocks = still catching up; Android-parity,
    // same getInfo sample. SDK's evaluateBestOf uses 288 — raise if probes filter everyone out.
    private static let syncedThresholdBlocks = 10

    var autoSelectEnabled: Bool {
        get { blockchainSettingsStorage.endpointAutoSelectEnabled(blockchainType: .zcash) }
        set { blockchainSettingsStorage.save(endpointAutoSelectEnabled: newValue, blockchainType: .zcash) }
    }

    // Persist without firing nodeUpdatedSubject: the auto-select engine has already switched the
    // live adapter itself, so the subject's adapter-switch path must not run a second time.
    func persistCurrent(node: ZcashNode, blockchainType: BlockchainType) {
        blockchainSettingsStorage.save(zcashNodeUrl: node.url.absoluteString, blockchainType: blockchainType)
    }

    // One probe serves both consumers: settings-screen badges (all nodes, nil = unreachable
    // or failed chain validation) and, via candidates(from:), the auto-select policy.
    func pingNodes(blockchainType: BlockchainType) async -> [NodePing] {
        let nodes = allNodes(blockchainType: blockchainType)
        let validated = await validatedProbe(nodes: nodes)

        return nodes.map { node in
            let probe = validated.first { $0.node == node }
            return NodePing(node: node, responseTime: probe?.responseTime, height: probe?.height ?? 0)
        }
    }

    // Auto-select candidates in the engine's projection: reachable, chain-valid nodes only.
    // Customs are https-only by construction (customNodes), so every reachable node qualifies.
    static func candidates(from pings: [NodePing]) -> [NodeAutoSelector.PingResult] {
        pings.compactMap { ping in
            guard let responseTime = ping.responseTime else { return nil }
            return NodeAutoSelector.PingResult(
                id: ping.node.url.absoluteString,
                responseTime: responseTime,
                height: UInt64(max(0, ping.height))
            )
        }
    }

    struct NodePing {
        let node: ZcashNode
        let responseTime: TimeInterval?
        let height: BlockHeight
    }

    private func validatedProbe(nodes: [ZcashNode]) async -> [(node: ZcashNode, responseTime: TimeInterval, height: BlockHeight)] {
        let network = ZcashNetworkBuilder.network(for: testNetManager.testNetEnabled ? .testnet : .mainnet)
        let expectedChainName = network.networkType == .mainnet ? "main" : "test"
        let expectedSaplingActivation = network.constants.saplingActivationHeight

        let results = await SDKSynchronizer.pingEndpoints(nodes.map { ZcashAdapter.endpoint(url: $0.url) })

        return results.compactMap { result in
            guard result.chainName == expectedChainName else { return nil }
            guard result.saplingActivationHeight == expectedSaplingActivation else { return nil }
            guard result.estimatedHeight - result.blockHeight < Self.syncedThresholdBlocks else { return nil }
            guard let node = nodes.first(where: { node in
                node.url.host == result.endpoint.host && (node.url.port ?? 443) == result.endpoint.port
            }) else { return nil }

            return (node: node, responseTime: result.responseTime, height: result.blockHeight)
        }
    }

    var customNodeRecords: [ZcashNodeRecord] {
        (try? zcashNodeStorage.getAll()) ?? []
    }

    var selectedNodes: [SelectedNode] {
        let type = BlockchainType.zcash
        return [
            SelectedNode(
                blockchainTypeUid: type.uid,
                url: node(blockchainType: type).url.absoluteString
            ),
        ]
    }
}

extension ZcashNodeManager {
    func encode(nodes: [ZcashNodeRecord]) -> [CustomNode] {
        nodes.map { node in
            CustomNode(blockchainTypeUid: node.blockchainTypeUid, url: node.url)
        }
    }

    func decode(nodes: [CustomNode]) -> [ZcashNodeRecord] {
        nodes.map { node in
            ZcashNodeRecord(blockchainTypeUid: node.blockchainTypeUid, url: node.url)
        }
    }
}

extension ZcashNodeManager {
    func restore(selected: [SelectedNode], custom: [ZcashNodeRecord], autoSelect: Bool?) {
        if let autoSelect {
            autoSelectEnabled = autoSelect
        }
        restore(selected: selected, custom: custom)
    }

    func restore(selected: [SelectedNode], custom: [ZcashNodeRecord]) {
        var blockchainTypes = Set<BlockchainType>()
        for node in custom {
            blockchainTypes.insert(BlockchainType(uid: node.blockchainTypeUid))
            try? zcashNodeStorage.save(record: node)
        }

        for selectedNode in selected {
            let blockchainType = BlockchainType(uid: selectedNode.blockchainTypeUid)
            if let node = allNodes(blockchainType: blockchainType)
                .first(where: { $0.url.absoluteString == selectedNode.url })
            {
                saveCurrent(nodeUrl: node.url, blockchainType: blockchainType)
            }
        }

        for blockchainType in blockchainTypes {
            nodeUpdatedSubject.send(blockchainType)
        }
    }
}

extension ZcashNodeManager {
    struct SelectedNode: Codable {
        let blockchainTypeUid: String
        let url: String

        enum CodingKeys: String, CodingKey {
            case blockchainTypeUid = "blockchain_type_id"
            case url
        }
    }

    struct CustomNode: Codable {
        let blockchainTypeUid: String
        let url: String

        enum CodingKeys: String, CodingKey {
            case blockchainTypeUid = "blockchain_type_id"
            case url
        }
    }

    struct NodeBackup: Codable {
        let selected: [SelectedNode]
        let custom: [CustomNode]
        // nullable: a backup made before the field existed must not override the device setting
        let autoSelect: Bool?

        enum CodingKeys: String, CodingKey {
            case selected
            case custom
            case autoSelect = "auto_select"
        }
    }
}

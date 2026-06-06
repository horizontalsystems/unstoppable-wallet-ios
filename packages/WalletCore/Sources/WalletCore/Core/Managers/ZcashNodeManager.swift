import Foundation
import MarketKit
import RxRelay
import RxSwift

class ZcashNodeManager {
    private let blockchainSettingsStorage: BlockchainSettingsStorage
    private let zcashNodeStorage: ZcashNodeStorage

    private let nodeRelay = PublishRelay<BlockchainType>()
    private let nodeUpdatedRelay = PublishRelay<BlockchainType>()

    init(blockchainSettingsStorage: BlockchainSettingsStorage, zcashNodeStorage: ZcashNodeStorage) {
        self.blockchainSettingsStorage = blockchainSettingsStorage
        self.zcashNodeStorage = zcashNodeStorage
    }

    private func saveCurrent(nodeUrl: URL, blockchainType: BlockchainType) {
        blockchainSettingsStorage.save(zcashNodeUrl: nodeUrl.absoluteString, blockchainType: blockchainType)
        nodeRelay.accept(blockchainType)
    }

    private func defaultNodes(blockchainType: BlockchainType) -> [ZcashNode] {
        switch blockchainType {
        case .zcash:
            return [
                ZcashNode(name: "zec.rocks", url: URL(string: "https://zec.rocks:443")!),
                ZcashNode(name: "na.zec.rocks", url: URL(string: "https://na.zec.rocks:443")!),
                ZcashNode(name: "sa.zec.rocks", url: URL(string: "https://sa.zec.rocks:443")!),
                ZcashNode(name: "eu.zec.rocks", url: URL(string: "https://eu.zec.rocks:443")!),
                ZcashNode(name: "ap.zec.rocks", url: URL(string: "https://ap.zec.rocks:443")!),
                ZcashNode(name: "us.zec.stardust.rest", url: URL(string: "https://us.zec.stardust.rest:443")!),
                ZcashNode(name: "eu.zec.stardust.rest", url: URL(string: "https://eu.zec.stardust.rest:443")!),
                ZcashNode(name: "eu2.zec.stardust.rest", url: URL(string: "https://eu2.zec.stardust.rest:443")!),
                ZcashNode(name: "jp.zec.stardust.rest", url: URL(string: "https://jp.zec.stardust.rest:443")!),
            ]
        default:
            return []
        }
    }
}

extension ZcashNodeManager {
    var nodeObservable: Observable<BlockchainType> {
        nodeRelay.asObservable()
    }

    var nodesUpdatedObservable: Observable<BlockchainType> {
        nodeUpdatedRelay.asObservable()
    }

    func customNodes(blockchainType: BlockchainType) -> [ZcashNode] {
        do {
            let records = try zcashNodeStorage.records(blockchainTypeUid: blockchainType.uid)
            return records.compactMap { record in
                guard let url = URL(string: record.url) else { return nil }
                return ZcashNode(name: url.host ?? "", url: url)
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

    func addNew(blockchainType: BlockchainType, url: URL) {
        let record = ZcashNodeRecord(blockchainTypeUid: blockchainType.uid, url: url.absoluteString)
        try? zcashNodeStorage.save(record: record)

        nodeUpdatedRelay.accept(blockchainType)
    }

    func delete(node: ZcashNode, blockchainType: BlockchainType) {
        let isCurrent = self.node(blockchainType: blockchainType) == node
        try? zcashNodeStorage.delete(blockchainTypeUid: blockchainType.uid, url: node.url.absoluteString)

        if isCurrent {
            nodeRelay.accept(blockchainType)
        }

        nodeUpdatedRelay.accept(blockchainType)
    }
}

extension ZcashNodeManager {
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
            nodeRelay.accept(blockchainType)
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
    }
}

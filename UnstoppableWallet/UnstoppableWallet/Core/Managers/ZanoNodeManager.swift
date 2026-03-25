import Foundation
import MarketKit
import RxRelay
import RxSwift

struct ZanoNode: Equatable {
    let name: String
    let url: URL
}

class ZanoNodeManager {
    private let blockchainSettingsStorage: BlockchainSettingsStorage
    private let zanoNodeStorage: ZanoNodeStorage

    private let nodeRelay = PublishRelay<BlockchainType>()
    private let nodeUpdatedRelay = PublishRelay<BlockchainType>()

    init(blockchainSettingsStorage: BlockchainSettingsStorage, zanoNodeStorage: ZanoNodeStorage) {
        self.blockchainSettingsStorage = blockchainSettingsStorage
        self.zanoNodeStorage = zanoNodeStorage
    }

    private func saveCurrent(nodeUrl: URL, blockchainType: BlockchainType) {
        blockchainSettingsStorage.save(zanoNodeUrl: nodeUrl.absoluteString, blockchainType: blockchainType)
        nodeRelay.accept(blockchainType)
    }

    private func defaultNodes(blockchainType: BlockchainType) -> [ZanoNode] {
        switch blockchainType {
        case .zano:
            return [
                ZanoNode(name: "zano.unstoppable.money", url: URL(string: "https://zano.unstoppable.money:443")!),
                ZanoNode(name: "node.zano.org", url: URL(string: "https://node.zano.org:443")!),
                ZanoNode(name: "37.27.100.59", url: URL(string: "http://37.27.100.59:10500")!),
            ]
        default:
            return []
        }
    }
}

extension ZanoNodeManager {
    var nodeObservable: Observable<BlockchainType> {
        nodeRelay.asObservable()
    }

    var nodesUpdatedObservable: Observable<BlockchainType> {
        nodeUpdatedRelay.asObservable()
    }

    func customNodes(blockchainType: BlockchainType) -> [ZanoNode] {
        do {
            let records = try zanoNodeStorage.records(blockchainTypeUid: blockchainType.uid)
            return records.compactMap { record in
                guard let url = URL(string: record.url) else { return nil }
                return ZanoNode(name: url.host ?? "", url: url)
            }
        } catch {
            return []
        }
    }

    func defaultAndCustomNodes(blockchainType: BlockchainType) -> ([ZanoNode], [ZanoNode]) {
        let defaultNodes = defaultNodes(blockchainType: blockchainType)
        let customNodes = customNodes(blockchainType: blockchainType)

        let filteredCustom = customNodes.filter { custom in
            !defaultNodes.contains(where: { $0.url.absoluteString == custom.url.absoluteString })
        }

        return (defaultNodes, filteredCustom)
    }

    func allNodes(blockchainType: BlockchainType) -> [ZanoNode] {
        let (defaultNodes, customNodes) = defaultAndCustomNodes(blockchainType: blockchainType)
        return defaultNodes + customNodes
    }

    func node(blockchainType: BlockchainType) -> ZanoNode {
        let nodes = allNodes(blockchainType: blockchainType)

        if let urlString = blockchainSettingsStorage.zanoNodeUrl(blockchainType: blockchainType),
           let node = nodes.first(where: { $0.url.absoluteString == urlString })
        {
            return node
        }

        return nodes[0]
    }

    func setCurrent(node: ZanoNode, blockchainType: BlockchainType) {
        saveCurrent(nodeUrl: node.url, blockchainType: blockchainType)
    }

    func addNew(blockchainType: BlockchainType, url: URL) {
        let record = ZanoNodeRecord(blockchainTypeUid: blockchainType.uid, url: url.absoluteString)
        try? zanoNodeStorage.save(record: record)

        nodeUpdatedRelay.accept(blockchainType)
    }

    func delete(node: ZanoNode, blockchainType: BlockchainType) {
        let isCurrent = self.node(blockchainType: blockchainType) == node
        try? zanoNodeStorage.delete(blockchainTypeUid: blockchainType.uid, url: node.url.absoluteString)

        if isCurrent {
            nodeRelay.accept(blockchainType)
        }

        nodeUpdatedRelay.accept(blockchainType)
    }
}

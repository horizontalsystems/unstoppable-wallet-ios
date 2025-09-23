import Foundation
import MarketKit
import MoneroKit
import RxRelay
import RxSwift

class MoneroNodeManager {
    private let blockchainSettingsStorage: BlockchainSettingsStorage
    private let moneroNodeStorage: MoneroNodeStorage

    private let nodeRelay = PublishRelay<BlockchainType>()
    private let nodeUpdatedRelay = PublishRelay<BlockchainType>()

    init(blockchainSettingsStorage: BlockchainSettingsStorage, moneroNodeStorage: MoneroNodeStorage) {
        self.blockchainSettingsStorage = blockchainSettingsStorage
        self.moneroNodeStorage = moneroNodeStorage
    }

    private func saveCurrent(nodeUrl: URL, blockchainType: BlockchainType) {
        blockchainSettingsStorage.save(moneroNodeUrl: nodeUrl.absoluteString, blockchainType: blockchainType)
        nodeRelay.accept(blockchainType)
    }

    private func saveNode(blockchainType: BlockchainType, url: URL, isTrusted: Bool, login: String? = nil, password: String? = nil) {
        let defaultNodes = defaultNodes(blockchainType: blockchainType)
        if let defaultNode = defaultNodes.first(where: { $0.node.url.absoluteString == url.absoluteString }),
           defaultNode.node.isTrusted == isTrusted, defaultNode.node.login == login, defaultNode.node.password == password
        {
            try? moneroNodeStorage.delete(blockchainTypeUid: blockchainType.uid, url: url.absoluteString)
        } else {
            let record = MoneroNodeRecord(
                blockchainTypeUid: blockchainType.uid,
                url: url.absoluteString,
                isTrusted: isTrusted,
                login: login,
                password: password
            )

            try? moneroNodeStorage.save(record: record)
        }

        nodeUpdatedRelay.accept(blockchainType)
    }

    private func defaultNodes(blockchainType: BlockchainType) -> [MoneroNode] {
        switch blockchainType {
        case .monero:
            return [
                MoneroNode(
                    name: "xmr-tw.org",
                    node: .init(url: URL(string: "opennode.xmr-tw.org:18089/mainnet/xmr-tw.org")!, isTrusted: false)
                ),
                MoneroNode(
                    name: "boldsuck.org",
                    node: .init(url: URL(string: "xmr-de.boldsuck.org:18081")!, isTrusted: false)
                ),
                MoneroNode(
                    name: "sethforprivacy.com",
                    node: .init(url: URL(string: "node.sethforprivacy.com:18089")!, isTrusted: false)
                ),
                MoneroNode(
                    name: "xmr.rocks",
                    node: .init(url: URL(string: "node.xmr.rocks:18089")!, isTrusted: false)
                ),
                MoneroNode(
                    name: "monerodevs.org",
                    node: .init(url: URL(string: "node.monerodevs.org:18089")!, isTrusted: false)
                ),
                MoneroNode(
                    name: "monerujo.io",
                    node: .init(url: URL(string: "nodex.monerujo.io:18081")!, isTrusted: false)
                ),
                MoneroNode(
                    name: "cakewallet.com",
                    node: .init(url: URL(string: "xmr-node.cakewallet.com:18081")!, isTrusted: false)
                ),
                MoneroNode(
                    name: "stackwallet.com",
                    node: .init(url: URL(string: "monero.stackwallet.com:18081")!, isTrusted: false)
                ),
                MoneroNode(
                    name: "hashvault.pro",
                    node: .init(url: URL(string: "nodes.hashvault.pro:18081")!, isTrusted: false)
                ),
            ]
        default:
            return []
        }
    }
}

extension MoneroNodeManager {
    var nodeObservable: Observable<BlockchainType> {
        nodeRelay.asObservable()
    }

    var nodesUpdatedObservable: Observable<BlockchainType> {
        nodeUpdatedRelay.asObservable()
    }

    func customNodes(blockchainType: BlockchainType?) -> [MoneroNode] {
        do {
            let records: [MoneroNodeRecord]
            if let blockchainType {
                records = try moneroNodeStorage.records(blockchainTypeUid: blockchainType.uid)
            } else {
                records = try moneroNodeStorage.getAll()
            }

            return records.compactMap { record in
                guard let url = URL(string: record.url) else {
                    return nil
                }

                return MoneroNode(
                    name: url.host ?? "",
                    node: .init(url: url, isTrusted: record.isTrusted, login: record.login, password: record.password)
                )
            }
        } catch {
            return []
        }
    }

    func defaultAndCustomNodes(blockchainType: BlockchainType) -> ([MoneroNode], [MoneroNode]) {
        var defaultNodes = defaultNodes(blockchainType: blockchainType)
        var customNodes = customNodes(blockchainType: blockchainType)

        for (index, defaultNode) in defaultNodes.enumerated() {
            if let customNodeIndex = customNodes.firstIndex(where: { $0.node.url.absoluteString == defaultNode.node.url.absoluteString }) {
                let customNode = customNodes[customNodeIndex]

                defaultNodes[index] = MoneroNode(
                    name: defaultNode.name,
                    node: .init(
                        url: defaultNode.node.url,
                        isTrusted: customNode.node.isTrusted,
                        login: customNode.node.login,
                        password: customNode.node.password
                    )
                )

                customNodes.remove(at: customNodeIndex)
            }
        }

        return (defaultNodes, customNodes)
    }

    func allNodes(blockchainType: BlockchainType) -> [MoneroNode] {
        let (defaultNodes, customNodes) = defaultAndCustomNodes(blockchainType: blockchainType)
        return defaultNodes + customNodes
    }

    func node(blockchainType: BlockchainType) -> MoneroNode {
        let nodes = allNodes(blockchainType: blockchainType)

        if let urlString = blockchainSettingsStorage.moneroNodeUrl(blockchainType: blockchainType),
           let node = nodes.first(where: { $0.node.url.absoluteString == urlString })
        {
            return node
        }

        return nodes[0]
    }

    func setCurrent(node: MoneroNode, blockchainType: BlockchainType) {
        saveNode(blockchainType: blockchainType, url: node.node.url, isTrusted: node.node.isTrusted)
        saveCurrent(nodeUrl: node.node.url, blockchainType: blockchainType)
    }

    func addNew(blockchainType: BlockchainType, url: URL, isTrusted: Bool, login: String? = nil, password: String? = nil) {
        saveNode(blockchainType: blockchainType, url: url, isTrusted: isTrusted, login: login, password: password)

        if let node = customNodes(blockchainType: blockchainType).first(where: { $0.node.url == url }) {
            saveCurrent(nodeUrl: node.node.url, blockchainType: blockchainType)
        }

        nodeUpdatedRelay.accept(blockchainType)
    }

    func delete(node: MoneroNode, blockchainType: BlockchainType) {
        let isCurrent = self.node(blockchainType: blockchainType) == node

        try? moneroNodeStorage.delete(blockchainTypeUid: blockchainType.uid, url: node.node.url.absoluteString)

        if isCurrent {
            nodeRelay.accept(blockchainType)
        }

        nodeUpdatedRelay.accept(blockchainType)
    }
}

extension MoneroNodeManager {
    var customNodeRecords: [MoneroNodeRecord] {
        (try? moneroNodeStorage.getAll()) ?? []
    }

    var selectedNodes: [SelectedNode] {
        let type = BlockchainType.monero
        return [
            SelectedNode(
                blockchainTypeUid: type.uid,
                url: node(blockchainType: type).node.url.absoluteString
            ),
        ]
    }
}

extension MoneroNodeManager {
    func decrypt(nodes: [CustomNode], passphrase: String) throws -> [MoneroNodeRecord] {
        try nodes.map { node in
            let password = try node.password
                .flatMap { try $0.decrypt(passphrase: passphrase) }
                .flatMap { String(data: $0, encoding: .utf8) }

            return MoneroNodeRecord(
                blockchainTypeUid: node.blockchainTypeUid,
                url: node.url,
                isTrusted: node.isTrusted,
                login: node.login,
                password: password
            )
        }
    }

    func encrypt(nodes: [MoneroNodeRecord], passphrase: String) throws -> [CustomNode] {
        try nodes.map { node in
            let crypto = try node.password
                .flatMap { $0.isEmpty ? nil : $0 }
                .flatMap { $0.data(using: .utf8) }
                .flatMap { try BackupCrypto.encrypt(data: $0, passphrase: passphrase) }

            return CustomNode(
                blockchainTypeUid: node.blockchainTypeUid,
                url: node.url,
                isTrusted: node.isTrusted,
                login: node.login,
                password: crypto
            )
        }
    }
}

extension MoneroNodeManager {
    func restore(selected: [SelectedNode], custom: [MoneroNodeRecord]) {
        var blockchainTypes = Set<BlockchainType>()
        for node in custom {
            blockchainTypes.insert(BlockchainType(uid: node.blockchainTypeUid))
            try? moneroNodeStorage.save(record: node)
        }

        for node in selected {
            let blockchainType = BlockchainType(uid: node.blockchainTypeUid)
            if let moneroNode = allNodes(blockchainType: blockchainType)
                .first(where: { $0.node.url.absoluteString == node.url })
            {
                saveCurrent(nodeUrl: moneroNode.node.url, blockchainType: blockchainType)
            }
        }

        for blockchainType in blockchainTypes {
            nodeRelay.accept(blockchainType)
        }
    }
}

extension MoneroNodeManager {
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
        let isTrusted: Bool
        let login: String?
        let password: BackupCrypto?

        enum CodingKeys: String, CodingKey {
            case blockchainTypeUid = "blockchain_type_id"
            case url
            case isTrusted
            case login
            case password
        }
    }

    struct NodeBackup: Codable {
        let selected: [SelectedNode]
        let custom: [CustomNode]
    }
}

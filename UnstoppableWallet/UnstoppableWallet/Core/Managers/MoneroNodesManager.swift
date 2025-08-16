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
}

extension MoneroNodeManager {
    var nodeObservable: Observable<BlockchainType> {
        nodeRelay.asObservable()
    }

    var nodesUpdatedObservable: Observable<BlockchainType> {
        nodeUpdatedRelay.asObservable()
    }

    func defaultNodes(blockchainType: BlockchainType) -> [MoneroNode] {
        switch blockchainType {
        case .monero:
            return [
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
                    )
            ]
        default:
            return []
        }
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

    func allNodes(blockchainType: BlockchainType) -> [MoneroNode] {
        defaultNodes(blockchainType: blockchainType) + customNodes(blockchainType: blockchainType)
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

    func saveCurrent(node: MoneroNode, blockchainType: BlockchainType) {
        blockchainSettingsStorage.save(moneroNodeUrl: node.node.url.absoluteString, blockchainType: blockchainType)
        nodeRelay.accept(blockchainType)
    }

    func saveNode(blockchainType: BlockchainType, url: URL, isTrusted: Bool, login: String? = nil, password: String? = nil) {
        let record = MoneroNodeRecord(
            blockchainTypeUid: blockchainType.uid,
            url: url.absoluteString,
            isTrusted: isTrusted,
            login: login,
            password: password
        )

        try? moneroNodeStorage.save(record: record)

        if let node = customNodes(blockchainType: blockchainType).first(where: { $0.node.url == url }) {
            saveCurrent(node: node, blockchainType: blockchainType)
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
                saveCurrent(node: moneroNode, blockchainType: blockchainType)
            }
        }

        for blockchainType in blockchainTypes {
            nodeUpdatedRelay.accept(blockchainType)
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

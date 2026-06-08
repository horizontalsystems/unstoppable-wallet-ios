import Foundation
import GRDB
import MarketKit
import Testing
@testable import Unstoppable
@testable import WalletCore

private struct ZcashNodeTestEnvironment {
    let dbPool: DatabasePool
    let manager: ZcashNodeManager

    init() throws {
        let dbURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("zcash-node-tests-\(UUID().uuidString).sqlite")
        let pool = try DatabasePool(path: dbURL.path)

        try pool.write { db in
            try db.create(table: ZcashNodeRecord.databaseTableName) { t in
                t.column(ZcashNodeRecord.Columns.blockchainTypeUid.name, .text).notNull()
                t.column(ZcashNodeRecord.Columns.url.name, .text).notNull()

                t.primaryKey([ZcashNodeRecord.Columns.blockchainTypeUid.name, ZcashNodeRecord.Columns.url.name], onConflict: .replace)
            }
            try db.create(table: BlockchainSettingRecord.databaseTableName) { t in
                t.column(BlockchainSettingRecord.Columns.blockchainUid.name, .text).notNull()
                t.column(BlockchainSettingRecord.Columns.key.name, .text).notNull()
                t.column(BlockchainSettingRecord.Columns.value.name, .text).notNull()

                t.primaryKey([BlockchainSettingRecord.Columns.blockchainUid.name, BlockchainSettingRecord.Columns.key.name], onConflict: .replace)
            }
        }

        dbPool = pool
        let zcashNodeStorage = ZcashNodeStorage(dbPool: pool)
        let settingRecordStorage = try BlockchainSettingRecordStorage(dbPool: pool)
        let settingsStorage = BlockchainSettingsStorage(storage: settingRecordStorage)
        manager = ZcashNodeManager(blockchainSettingsStorage: settingsStorage, zcashNodeStorage: zcashNodeStorage)
    }
}

struct ZcashNodeManagerTests {
    private let zcash = BlockchainType.zcash

    @Test func defaultListStartsWithZecRocks() throws {
        let env = try ZcashNodeTestEnvironment()
        let (defaults, custom) = env.manager.defaultAndCustomNodes(blockchainType: zcash)

        #expect(defaults.count == 9)
        #expect(custom.isEmpty)
        #expect(defaults.first?.name == "zec.rocks")
        #expect(defaults.first?.url.absoluteString == "https://zec.rocks:443")
    }

    @Test func defaultSelectionIsFirstDefault() throws {
        let env = try ZcashNodeTestEnvironment()
        let selected = env.manager.node(blockchainType: zcash)
        #expect(selected.url.absoluteString == "https://zec.rocks:443")
    }

    @Test func setCurrentPersistsSelection() throws {
        let env = try ZcashNodeTestEnvironment()
        let target = ZcashNode(name: "eu.zec.rocks", url: URL(string: "https://eu.zec.rocks:443")!)

        env.manager.setCurrent(node: target, blockchainType: zcash)

        #expect(env.manager.node(blockchainType: zcash).url == target.url)
    }

    @Test func addNewCustomNodeAppears() throws {
        let env = try ZcashNodeTestEnvironment()
        try env.manager.addNew(blockchainType: zcash, url: URL(string: "https://my.lightwalletd.example:9067")!)

        let (_, custom) = env.manager.defaultAndCustomNodes(blockchainType: zcash)
        #expect(custom.contains { $0.url.absoluteString == "https://my.lightwalletd.example:9067" })
        // custom node name is derived from the host
        #expect(custom.first?.name == "my.lightwalletd.example")
    }

    @Test func customMatchingDefaultIsDeduped() throws {
        let env = try ZcashNodeTestEnvironment()
        try env.manager.addNew(blockchainType: zcash, url: URL(string: "https://zec.rocks:443")!)

        let (defaults, custom) = env.manager.defaultAndCustomNodes(blockchainType: zcash)
        #expect(!custom.contains { $0.url.absoluteString == "https://zec.rocks:443" })
        #expect(defaults.contains { $0.url.absoluteString == "https://zec.rocks:443" })
    }

    @Test func customNodeWithUnsupportedSchemeIsIgnored() throws {
        let env = try ZcashNodeTestEnvironment()
        try env.manager.addNew(blockchainType: zcash, url: URL(string: "wss://my.lightwalletd.example:443")!)

        let (_, custom) = env.manager.defaultAndCustomNodes(blockchainType: zcash)
        #expect(custom.isEmpty)
    }

    @Test func deletingSelectedCustomFallsBackToDefault() throws {
        let env = try ZcashNodeTestEnvironment()
        let custom = ZcashNode(name: "my.lightwalletd.example", url: URL(string: "https://my.lightwalletd.example:9067")!)

        try env.manager.addNew(blockchainType: zcash, url: custom.url)
        env.manager.setCurrent(node: custom, blockchainType: zcash)
        #expect(env.manager.node(blockchainType: zcash).url == custom.url)

        try env.manager.delete(node: custom, blockchainType: zcash)
        #expect(env.manager.node(blockchainType: zcash).url.absoluteString == "https://zec.rocks:443")
    }

    @Test func backupEncodeDecodeRoundTrip() throws {
        let env = try ZcashNodeTestEnvironment()
        try env.manager.addNew(blockchainType: zcash, url: URL(string: "https://a.example:443")!)
        try env.manager.addNew(blockchainType: zcash, url: URL(string: "https://b.example:9067")!)

        let records = env.manager.customNodeRecords
        let encoded = env.manager.encode(nodes: records)
        let decoded = env.manager.decode(nodes: encoded)

        #expect(decoded.count == records.count)
        let decodedUrls = Set(decoded.map(\.url))
        #expect(decodedUrls.contains("https://a.example:443"))
        #expect(decodedUrls.contains("https://b.example:9067"))
    }

    @Test func backupRestoreReinstatesCustomAndSelection() throws {
        let env = try ZcashNodeTestEnvironment()
        let custom = ZcashNodeRecord(blockchainTypeUid: zcash.uid, url: "https://restored.example:443")
        let selected = ZcashNodeManager.SelectedNode(blockchainTypeUid: zcash.uid, url: "https://restored.example:443")

        env.manager.restore(selected: [selected], custom: [custom])

        let (_, customNodes) = env.manager.defaultAndCustomNodes(blockchainType: zcash)
        #expect(customNodes.contains { $0.url.absoluteString == "https://restored.example:443" })
        #expect(env.manager.node(blockchainType: zcash).url.absoluteString == "https://restored.example:443")
    }
}

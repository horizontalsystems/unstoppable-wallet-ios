import Combine
import Foundation
import GRDB
import MarketKit
import NearKit
import Testing
@testable import WalletCore

private struct NearNodeTestEnvironment {
    let dbPool: DatabasePool
    let settingsStorage: BlockchainSettingsStorage
    let manager: NearNodeManager

    init() throws {
        let dbURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("near-node-tests-\(UUID().uuidString).sqlite")
        let pool = try DatabasePool(path: dbURL.path)

        try pool.write { db in
            try db.create(table: BlockchainSettingRecord.databaseTableName) { t in
                t.column(BlockchainSettingRecord.Columns.blockchainUid.name, .text).notNull()
                t.column(BlockchainSettingRecord.Columns.key.name, .text).notNull()
                t.column(BlockchainSettingRecord.Columns.value.name, .text).notNull()

                t.primaryKey([BlockchainSettingRecord.Columns.blockchainUid.name, BlockchainSettingRecord.Columns.key.name], onConflict: .replace)
            }
        }

        dbPool = pool
        let settingRecordStorage = try BlockchainSettingRecordStorage(dbPool: pool)
        settingsStorage = BlockchainSettingsStorage(storage: settingRecordStorage)
        manager = NearNodeManager(blockchainSettingsStorage: settingsStorage)
    }
}

struct NearNodeManagerTests {
    private let mainNet = NearKit.Network.mainNet
    private let testNet = NearKit.Network.testNet

    /// Android NearRpcSourceManager names over the kit's own list
    @Test func listComesFromTheKitWithAndroidNames() throws {
        let env = try NearNodeTestEnvironment()

        let mainNodes = env.manager.allNodes(network: mainNet)
        #expect(mainNodes.map(\.url) == mainNet.rpcUrls)
        #expect(mainNodes.map(\.name) == ["FastNEAR", "dRPC", "Shitzu", "NEAR.org"])

        let testNodes = env.manager.allNodes(network: testNet)
        #expect(testNodes.map(\.url) == testNet.rpcUrls)
        #expect(testNodes.map(\.name) == ["FastNEAR", "NEAR.org"])
    }

    @Test func defaultSelectionIsTheKitsFirstNode() throws {
        let env = try NearNodeTestEnvironment()
        #expect(env.manager.node(network: mainNet).url == mainNet.rpcUrls[0])
        #expect(env.manager.node(network: testNet).url == testNet.rpcUrls[0])
    }

    @Test func setCurrentPersistsSelection() throws {
        let env = try NearNodeTestEnvironment()
        let target = env.manager.allNodes(network: mainNet)[2]

        env.manager.setCurrent(node: target, network: mainNet)

        // a fresh manager over the same storage reads the choice back
        let reloaded = NearNodeManager(blockchainSettingsStorage: env.settingsStorage)
        #expect(reloaded.node(network: mainNet).url == target.url)
    }

    /// The choice reorders the kit's failover list rather than shortening it
    @Test func selectedNodeLeadsTheFailoverList() throws {
        let env = try NearNodeTestEnvironment()
        let target = env.manager.allNodes(network: mainNet)[2]

        env.manager.setCurrent(node: target, network: mainNet)

        #expect(env.manager.rpcUrls(network: mainNet) == [target.url] + mainNet.rpcUrls.filter { $0 != target.url })
    }

    @Test func untouchedSelectionKeepsTheKitsOrder() throws {
        let env = try NearNodeTestEnvironment()
        #expect(env.manager.rpcUrls(network: mainNet) == mainNet.rpcUrls)
    }

    /// a stored url the kit no longer lists falls back to its first node
    @Test func unknownStoredNodeFallsBackToTheFirst() throws {
        let env = try NearNodeTestEnvironment()

        env.settingsStorage.save(nearNodeUrl: "https://gone.example.org/", blockchainType: .near, testNet: false)

        #expect(env.manager.node(network: mainNet).url == mainNet.rpcUrls[0])
        #expect(env.manager.rpcUrls(network: mainNet) == mainNet.rpcUrls)
    }

    @Test func selectionDoesNotLeakAcrossNetworks() throws {
        let env = try NearNodeTestEnvironment()
        let mainTarget = env.manager.allNodes(network: mainNet)[1]

        env.manager.setCurrent(node: mainTarget, network: mainNet)

        #expect(env.manager.node(network: testNet).url == testNet.rpcUrls[0])
        #expect(env.manager.rpcUrls(network: testNet) == testNet.rpcUrls)
        #expect(env.manager.node(network: mainNet).url == mainTarget.url)
    }

    @Test func netChoiceDoesNotOverwriteMainnetChoice() throws {
        let env = try NearNodeTestEnvironment()
        let mainTarget = env.manager.allNodes(network: mainNet)[2]
        let testTarget = env.manager.allNodes(network: testNet)[1]

        env.manager.setCurrent(node: mainTarget, network: mainNet)
        env.manager.setCurrent(node: testTarget, network: testNet)

        #expect(env.manager.node(network: mainNet).url == mainTarget.url)
        #expect(env.manager.node(network: testNet).url == testTarget.url)
    }

    @Test func nodeUpdateIsPublished() throws {
        let env = try NearNodeTestEnvironment()
        var published = [BlockchainType]()
        let cancellable = env.manager.nodeUpdatedPublisher.sink { published.append($0) }
        defer { cancellable.cancel() }

        env.manager.setCurrent(node: env.manager.allNodes(network: mainNet)[1], network: mainNet)

        #expect(published == [.near])
    }
}

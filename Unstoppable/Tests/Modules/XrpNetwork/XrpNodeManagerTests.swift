import Combine
import Foundation
import GRDB
import MarketKit
import Testing
@testable import WalletCore
import XrpKit

private struct XrpNodeTestEnvironment {
    let dbPool: DatabasePool
    let manager: XrpNodeManager

    init() throws {
        let dbURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("xrp-node-tests-\(UUID().uuidString).sqlite")
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
        manager = XrpNodeManager(blockchainSettingsStorage: BlockchainSettingsStorage(storage: settingRecordStorage))
    }
}

struct XrpNodeManagerTests {
    private let mainNet = XrpKit.Network.mainNet
    private let testNet = XrpKit.Network.testNet

    @Test func listComesFromTheKitWithHostNames() throws {
        let env = try XrpNodeTestEnvironment()
        let nodes = env.manager.allNodes(network: mainNet)

        #expect(nodes.map(\.url) == mainNet.rpcUrls)
        #expect(nodes.first?.name == "xrplcluster.com")
    }

    @Test func defaultSelectionIsTheKitsFirstNode() throws {
        let env = try XrpNodeTestEnvironment()
        #expect(env.manager.node(network: mainNet).url == mainNet.rpcUrls[0])
    }

    @Test func setCurrentPersistsSelection() throws {
        let env = try XrpNodeTestEnvironment()
        let target = env.manager.allNodes(network: mainNet)[2]

        env.manager.setCurrent(node: target, network: mainNet)

        #expect(env.manager.node(network: mainNet).url == target.url)
    }

    // The choice reorders the kit's failover list rather than shortening it (Android rotation)
    @Test func selectedNodeLeadsTheFailoverList() throws {
        let env = try XrpNodeTestEnvironment()
        let target = env.manager.allNodes(network: mainNet)[2]

        env.manager.setCurrent(node: target, network: mainNet)
        let urls = env.manager.rpcUrls(network: mainNet)

        #expect(urls.first == target.url)
        #expect(Set(urls) == Set(mainNet.rpcUrls))
        #expect(urls.count == mainNet.rpcUrls.count)
    }

    @Test func untouchedSelectionKeepsTheKitsOrder() throws {
        let env = try XrpNodeTestEnvironment()
        #expect(env.manager.rpcUrls(network: mainNet) == mainNet.rpcUrls)
    }

    // A node stored for one network does not exist on the other, so each keeps its own choice
    @Test func selectionDoesNotLeakAcrossNetworks() throws {
        let env = try XrpNodeTestEnvironment()
        let target = env.manager.allNodes(network: mainNet)[1]

        env.manager.setCurrent(node: target, network: mainNet)

        #expect(env.manager.node(network: testNet).url == testNet.rpcUrls[0])
        #expect(env.manager.rpcUrls(network: testNet) == testNet.rpcUrls)
        #expect(env.manager.node(network: mainNet).url == target.url)
    }

    @Test func nodeUpdateIsPublished() throws {
        let env = try XrpNodeTestEnvironment()
        var published = [BlockchainType]()
        let cancellable = env.manager.nodeUpdatedPublisher.sink { published.append($0) }
        defer { cancellable.cancel() }

        env.manager.setCurrent(node: env.manager.allNodes(network: mainNet)[1], network: mainNet)

        #expect(published == [.xrp])
    }
}

import Foundation
import GRDB
import MarketKit
import Testing
import ThorChainKit
@testable import WalletCore

struct ThorChainEndpointManagerTests {
    @Test func selectedFamilyPersistsAndBuildsSingleFamilyConfiguration() throws {
        let environment = try EndpointTestEnvironment()
        let families = try environment.manager.endpointFamilies()

        #expect(try environment.manager.endpointFamily().id == "first")

        try environment.manager.setCurrent(endpointFamily: families[1])

        let reloaded = environment.reloaded()
        #expect(try reloaded.endpointFamily().id == "second")
        #expect(try reloaded.endpointConfiguration().value.families.map(\.id) == ["second"])
    }

    @Test func selectedFamilyKeepsConfiguredMidgardURLs() throws {
        let environment = try EndpointTestEnvironment()

        let configuration = try environment.manager.endpointConfiguration()

        #expect(configuration.value.midgardURLs == [URL(string: "https://midgard.example/api/")!])
    }

    @Test func backupRestoresSelectedFamily() throws {
        let source = try EndpointTestEnvironment()
        try source.manager.setCurrent(endpointFamily: source.manager.endpointFamilies()[1])

        let restored = try EndpointTestEnvironment()
        restored.manager.restore(backup: source.manager.backup)

        #expect(try restored.manager.endpointFamily().id == "second")
    }

    @Test func restoreIgnoresUnknownFamily() throws {
        let environment = try EndpointTestEnvironment()

        environment.manager.restore(backup: .init(familyId: "unknown"))

        #expect(try environment.manager.endpointFamily().id == "first")
    }
}

private struct EndpointTestEnvironment {
    let manager: ThorChainEndpointManager
    private let settingsStorage: BlockchainSettingsStorage

    // A second manager over the same storage: reading back through the one that wrote
    // proves nothing about what was persisted.
    func reloaded() -> ThorChainEndpointManager {
        ThorChainEndpointManager(
            blockchainSettingsStorage: settingsStorage,
            endpointProvider: StaticThorChainEndpointProvider()
        )
    }

    init() throws {
        let databaseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("thorchain-endpoint-tests-\(UUID().uuidString).sqlite")
        let dbPool = try DatabasePool(path: databaseURL.path)

        try dbPool.write { db in
            try db.create(table: BlockchainSettingRecord.databaseTableName) { table in
                table.column(BlockchainSettingRecord.Columns.blockchainUid.name, .text).notNull()
                table.column(BlockchainSettingRecord.Columns.key.name, .text).notNull()
                table.column(BlockchainSettingRecord.Columns.value.name, .text).notNull()
                table.primaryKey([BlockchainSettingRecord.Columns.blockchainUid.name, BlockchainSettingRecord.Columns.key.name], onConflict: .replace)
            }
        }

        let recordStorage = try BlockchainSettingRecordStorage(dbPool: dbPool)
        settingsStorage = BlockchainSettingsStorage(storage: recordStorage)
        manager = ThorChainEndpointManager(
            blockchainSettingsStorage: settingsStorage,
            endpointProvider: StaticThorChainEndpointProvider()
        )
    }
}

private struct StaticThorChainEndpointProvider: IThorChainEndpointConfigurationProvider {
    func configuration() throws -> ThorChainEndpointConfiguration {
        let first = try ThorChainKit.EndpointFamilyDescriptor(
            id: "first",
            cosmosRestURL: URL(string: "https://first-rest.example")!,
            cometBftURL: URL(string: "https://first-rpc.example")!
        )
        let second = try ThorChainKit.EndpointFamilyDescriptor(
            id: "second",
            cosmosRestURL: URL(string: "https://second-rest.example")!,
            cometBftURL: URL(string: "https://second-rpc.example")!
        )

        return try ThorChainEndpointConfiguration(
            value: ThorChainKit.EndpointConfiguration(
                families: [first, second],
                midgardURLs: [URL(string: "https://midgard.example/api/")!]
            ),
            approvedMainnetHosts: ["first-rest.example", "first-rpc.example", "second-rest.example", "second-rpc.example", "midgard.example"]
        )
    }
}

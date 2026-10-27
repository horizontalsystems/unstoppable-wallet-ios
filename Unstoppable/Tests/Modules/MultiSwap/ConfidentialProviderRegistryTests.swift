import Foundation
import GRDB
import HsToolKit
import ObjectMapper
import Testing
@testable import WalletCore

// The server's confidential list is stored whole; only ids with a registered, confidential USwapProviderInfo are offered
struct ConfidentialProviderRegistryTests {
    @Test func unknownIdsAreHiddenOnRead() throws {
        let storage = try Self.storage(providerIds: ["NEAR_CONFIDENTIAL", "NEAR_CONFIDENTIAL_ADVANCED"])
        let registry = Self.registry(storage: storage, isUsableProvider: { $0 == "NEAR_CONFIDENTIAL" })

        #expect(registry.providerIds == ["NEAR_CONFIDENTIAL"])
        #expect(try storage.providerIds().sorted() == ["NEAR_CONFIDENTIAL", "NEAR_CONFIDENTIAL_ADVANCED"])
    }

    @Test func knownIdsPassThrough() throws {
        let storage = try Self.storage(providerIds: ["NEAR_CONFIDENTIAL", "NEAR_CONFIDENTIAL_ADVANCED"])
        let registry = Self.registry(storage: storage, isUsableProvider: { _ in true })

        #expect(registry.providerIds == ["NEAR_CONFIDENTIAL", "NEAR_CONFIDENTIAL_ADVANCED"])
    }

    @Test func fallbackIsFilteredToo() throws {
        let storage = try Self.storage(providerIds: [])
        let registry = Self.registry(storage: storage, fallbackIds: ["A", "B"], isUsableProvider: { $0 == "B" })

        #expect(registry.providerIds == ["B"])
    }

    // An empty storage leaves the registry unsynced, so `init` fires a sync; the API points at a closed
    // local port so it fails fast and keeps the seed instead of reaching the live server.
    static func registry(
        storage: ConfidentialProviderStorage,
        fallbackIds: [String] = ["NEAR_CONFIDENTIAL"],
        isUsableProvider: ((String) -> Bool)? = nil
    ) -> ConfidentialProviderRegistry {
        let api = USwapMultiSwapApi(baseURL: URL(string: "http://127.0.0.1:1/v3")!, apiKey: nil, networkManager: NetworkManager())

        if let isUsableProvider {
            return ConfidentialProviderRegistry(api: api, storage: storage, fallbackIds: fallbackIds, isUsableProvider: isUsableProvider)
        }

        return ConfidentialProviderRegistry(api: api, storage: storage, fallbackIds: fallbackIds)
    }

    // The table as StorageMigrator leaves it; the migrator itself touches the app keychain, so it is not run here.
    // Seeded with a fresh timestamp so the registry's TTL skips the sync.
    static func storage(providerIds: [String]) throws -> ConfidentialProviderStorage {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("confidential-provider-registry-tests-\(UUID().uuidString).sqlite").path
        let dbPool = try DatabasePool(path: path)

        try dbPool.write { db in
            try db.create(table: ConfidentialProviderRecord.databaseTableName) { t in
                t.column(ConfidentialProviderRecord.Columns.providerId.name, .text).notNull().primaryKey(onConflict: .replace)
                t.column(ConfidentialProviderRecord.Columns.executionType.name, .text).notNull()
                t.column(ConfidentialProviderRecord.Columns.lastSyncTimestamp.name, .double).notNull()
            }
        }

        let storage = ConfidentialProviderStorage(dbPool: dbPool)
        try storage.save(
            providerIds: providerIds,
            executionTypes: Dictionary(uniqueKeysWithValues: providerIds.map { ($0, "transfer") }),
            lastSyncTimestamp: Date().timeIntervalSince1970
        )
        return storage
    }
}

// Lives in the serialized SwapProviderFactoryTests suite (whose init resets the factory) because
// SwapProviderFactory is global mutable state that a parallel suite would race on.
extension SwapProviderFactoryTests {
    // NEAR is registered but not confidential locally; NEAR_CONFIDENTIAL_ADVANCED is not registered
    @Test func confidentialRegistryDefaultCheckRequiresLocalConfidentialFlag() throws {
        SwapProviderFactory.register([SwapProviderResolver.self])
        defer { SwapProviderFactory.reset() }

        let storage = try ConfidentialProviderRegistryTests.storage(providerIds: [])
        let registry = ConfidentialProviderRegistryTests.registry(
            storage: storage,
            fallbackIds: ["NEAR_CONFIDENTIAL", "NEAR", "NEAR_CONFIDENTIAL_ADVANCED"]
        )

        #expect(registry.providerIds == ["NEAR_CONFIDENTIAL"])
    }
}

extension SwapProviderFactoryTests {
    // SWAPUZ_SPLIT reports `privacy: "split"`, which marks the descriptor confidential (NEAR_CONFIDENTIAL_ADVANCED
    // needs that), so the sync stores it; the default check drops it on read because its local info is not confidential
    @Test func splitSwapProviderIsNotOfferedForPrivateSend() throws {
        SwapProviderFactory.register([SwapProviderResolver.self])
        defer { SwapProviderFactory.reset() }

        let descriptors = try [
            ["provider": "NEAR_CONFIDENTIAL", "executionType": "transfer", "privacy": "basic", "suspended": false],
            ["provider": "SWAPUZ_SPLIT", "executionType": "transfer", "privacy": "split", "suspended": false],
        ].map { try Mapper<USwapMultiSwapApi.ProviderDescriptorResponse>().map(JSON: $0).descriptor }

        // the filter the registry's sync applies before storing the list
        let synced = descriptors.filter { $0.confidential && !$0.suspended && $0.executionType == "transfer" }.map(\.id)
        #expect(synced == ["NEAR_CONFIDENTIAL", "SWAPUZ_SPLIT"])

        let storage = try ConfidentialProviderRegistryTests.storage(providerIds: synced)
        let registry = ConfidentialProviderRegistryTests.registry(storage: storage)

        #expect(registry.providerIds.contains("NEAR_CONFIDENTIAL"))
        #expect(!registry.providerIds.contains("SWAPUZ_SPLIT"))
    }
}

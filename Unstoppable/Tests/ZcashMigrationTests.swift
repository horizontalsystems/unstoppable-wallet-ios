import Foundation
import GRDB
import Testing
@testable import WalletCore
import ZcashLightClientKit

struct ZcashMigrationTests {
    private static let fee = Zatoshi(15000)

    private func makeMigrator(
        uniqueId: String = UUID().uuidString,
        networkType: NetworkType = .mainnet,
        storage: ZcashAdapterStorage? = nil
    ) throws -> (ZcashMigrator, ZcashAdapterStorage) {
        let storage = try storage ?? makeStorage()
        let migrator = ZcashMigrator(
            uniqueId: uniqueId,
            threshold: ZcashAdapter.minimalThreshold,
            network: ZcashNetworkBuilder.network(for: networkType),
            storage: storage,
            logger: nil
        )
        return (migrator, storage)
    }

    private func makeStorage() throws -> ZcashAdapterStorage {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("zcash-migration-tests-\(UUID().uuidString).sqlite").path
        let dbPool = try DatabasePool(path: path)
        return try ZcashAdapterStorage(dbPool: dbPool)
    }

    // MARK: - Suggestion predicate

    @Test func predicateTable() {
        func needed(migrationEnabled: Bool = true, ironwoodActive: Bool = true, syncStatus: SyncStatus = .upToDate,
                    orchardSpendable: Decimal = 1, threshold: Decimal = 0.0004, alertShown: Bool = false) -> Bool
        {
            ZcashMigrator.isMigrationSuggestionNeeded(
                migrationEnabled: migrationEnabled, ironwoodActive: ironwoodActive, syncStatus: syncStatus,
                orchardSpendable: orchardSpendable, threshold: threshold, alertShown: alertShown
            )
        }

        #expect(needed())
        #expect(!needed(migrationEnabled: false))
        #expect(!needed(ironwoodActive: false))
        #expect(!needed(syncStatus: .syncing(0.5, false)))
        #expect(!needed(syncStatus: .unprepared))
        // send-max leaves no privacy buffer: once the swept notes go pending-spent the balance drops
        // to/below the threshold and the predicate is false on its own — no timestamp suppression needed.
        #expect(!needed(orchardSpendable: 0.0004))
        #expect(!needed(alertShown: true))
    }

    // MARK: - Migration (send-max)

    @Test func successfulMigrationSavesRecord() async throws {
        let (migrator, storage) = try makeMigrator(uniqueId: "acc-1")
        let engine = MockMigrationEngine()
        migrator.engine = engine

        let txId = try await migrator.performMigration()

        let unwrappedTxId = try #require(txId)
        #expect(engine.executedTxIds == [unwrappedTxId])

        let storedIds = try storage.migrationTxIds(accountId: "acc-1")
        #expect(storedIds == [unwrappedTxId])
    }

    @Test func dustBalanceThrowsNotEnough() async throws {
        let (migrator, storage) = try makeMigrator(uniqueId: "acc-dust")
        migrator.engine = MockMigrationEngine(orchardSpendable: Zatoshi(10000)) // below fake fee

        var notEnough = false
        do {
            _ = try await migrator.performMigration()
        } catch AppError.ZcashError.notEnough {
            notEnough = true
        }

        #expect(notEnough)
        #expect(try storage.migrationTxIds(accountId: "acc-dust").isEmpty) // nothing broadcast, nothing recorded
    }

    @Test func proposalAmountAndFee() async throws {
        let (migrator, _) = try makeMigrator()
        migrator.engine = MockMigrationEngine() // spendable well above fee

        let orchardBalance: Decimal = 1
        let proposal = try await migrator.migrationProposal(orchardBalance: orchardBalance)

        let fee = Self.fee.decimalValue.decimalValue
        #expect(proposal.fee == fee) // fee is authoritative from the proposal, asserted independently
        #expect(proposal.amount == orchardBalance - fee) // amount is the swept shielded balance minus fee
    }

    @Test func proposalThrowsNotEnoughWhenFeeConsumesBalance() async throws {
        let (migrator, _) = try makeMigrator()
        migrator.engine = MockMigrationEngine()

        // balance exactly equal to the fee → amount == 0 → notEnough (boundary, not just `< fee`)
        var notEnough = false
        do {
            _ = try await migrator.migrationProposal(orchardBalance: Self.fee.decimalValue.decimalValue)
        } catch AppError.ZcashError.notEnough {
            notEnough = true
        }

        #expect(notEnough)
    }

    @Test func isMigrationTxMatchesOnlyStoredRecords() async throws {
        let (migrator, _) = try makeMigrator(uniqueId: "acc-match")
        migrator.engine = MockMigrationEngine()

        let txId = try await migrator.performMigration()

        let unwrappedTxId = try #require(txId)
        #expect(migrator.isMigrationTx(hash: unwrappedTxId))
        #expect(!migrator.isMigrationTx(hash: String(repeating: "0", count: 64)))
    }

    // MARK: - Activation boundary

    @Test func ironwoodActivationBoundary() throws {
        let (migrator, _) = try makeMigrator(networkType: .mainnet)
        let network = ZcashNetworkBuilder.network(for: .mainnet)
        let activation = try #require(network.ironwoodActivationHeight)

        #expect(!migrator.ironwoodActive(latestHeight: activation - 1))
        #expect(migrator.ironwoodActive(latestHeight: activation))
    }

    // MARK: - Wallet isolation

    @Test func recordsAreIsolatedPerAccount() async throws {
        let storage = try makeStorage()
        let (migratorA, _) = try makeMigrator(uniqueId: "acc-a", storage: storage)
        let (migratorB, _) = try makeMigrator(uniqueId: "acc-b", storage: storage)
        migratorA.engine = MockMigrationEngine()

        _ = try await migratorA.performMigration()

        #expect(try storage.migrationTxIds(accountId: "acc-a").count == 1)
        #expect(try storage.migrationTxIds(accountId: "acc-b").isEmpty)

        migratorB.clearOnWipe()
        #expect(try storage.migrationTxIds(accountId: "acc-a").count == 1) // wiping B must not touch A

        migratorA.clearOnWipe()
        #expect(try storage.migrationTxIds(accountId: "acc-a").isEmpty)
    }
}

// Test double for the send-max migration engine: fixed fee, sweeps its emulated balance to a fake txid.
private final class MockMigrationEngine: IZcashMigrationEngine {
    private static let fee = Zatoshi(15000)

    private(set) var orchardSpendable: Zatoshi
    private(set) var executedTxIds = [String]()

    init(orchardSpendable: Zatoshi = Zatoshi(100_000_000)) {
        self.orchardSpendable = orchardSpendable
    }

    func estimatedFee() async throws -> Zatoshi {
        guard orchardSpendable > Self.fee else {
            throw AppError.ZcashError.notEnough
        }
        return Self.fee
    }

    func migrate() async throws -> String? {
        guard orchardSpendable > Self.fee else {
            throw AppError.ZcashError.notEnough
        }
        let txId = (UUID().uuidString + UUID().uuidString).replacingOccurrences(of: "-", with: "").lowercased()
        executedTxIds.append(txId)
        orchardSpendable = Zatoshi(0)
        return txId
    }
}

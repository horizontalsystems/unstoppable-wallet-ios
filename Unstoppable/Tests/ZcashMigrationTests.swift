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
                    orchardSpendable: Decimal = 1, threshold: Decimal = 0.0004, alertShown: Bool = false,
                    migrationTimestamp: Date? = nil, now: Date = Date()) -> Bool
        {
            ZcashMigrator.isMigrationSuggestionNeeded(
                migrationEnabled: migrationEnabled, ironwoodActive: ironwoodActive, syncStatus: syncStatus,
                orchardSpendable: orchardSpendable, threshold: threshold, alertShown: alertShown,
                migrationTimestamp: migrationTimestamp, now: now
            )
        }

        #expect(needed())
        #expect(!needed(migrationEnabled: false))
        #expect(!needed(ironwoodActive: false))
        #expect(!needed(syncStatus: .syncing(0.5, false)))
        #expect(!needed(syncStatus: .unprepared))
        #expect(!needed(orchardSpendable: 0.0004))
        #expect(!needed(alertShown: true))
    }

    @Test func predicateTimestampWindow() {
        let now = Date()
        let inWindow = ZcashMigrator.isMigrationSuggestionNeeded(
            migrationEnabled: true, ironwoodActive: true, syncStatus: .upToDate,
            orchardSpendable: 1, threshold: 0.0004, alertShown: false,
            migrationTimestamp: now.addingTimeInterval(-ZcashMigrator.bufferInterval + 10), now: now
        )
        let afterWindow = ZcashMigrator.isMigrationSuggestionNeeded(
            migrationEnabled: true, ironwoodActive: true, syncStatus: .upToDate,
            orchardSpendable: 1, threshold: 0.0004, alertShown: false,
            migrationTimestamp: now.addingTimeInterval(-ZcashMigrator.bufferInterval - 10), now: now
        )
        #expect(!inWindow)
        #expect(afterWindow)
    }

    // MARK: - Session

    @Test func successfulMigrationSavesRecord() async throws {
        let (migrator, storage) = try makeMigrator(uniqueId: "acc-1")
        let engine = FakeZcashMigrationEngine()
        migrator.engine = engine

        let txId = try await migrator.performMigration(currentEndpointHost: "zec.rocks")

        let unwrappedTxId = try #require(txId)
        #expect(engine.executedTxIds == [unwrappedTxId])

        let storedIds = try storage.migrationTxIds(accountId: "acc-1")
        #expect(storedIds == [unwrappedTxId])
        let timestamp = try #require(migrator.timestamp)
        #expect(abs(timestamp.timeIntervalSinceNow) < 5)
    }

    @Test func retryableNetworkErrorIsRetried() async throws {
        let (migrator, _) = try makeMigrator()
        let engine = FakeZcashMigrationEngine(executeResults: [.networkError(retryable: true)])
        migrator.engine = engine

        let txId = try await migrator.performMigration(currentEndpointHost: "zec.rocks")

        #expect(txId != nil)
        #expect(engine.executedTxIds.count == 1)
    }

    @Test func retriesExhaustAfterTwoAttempts() async throws {
        let (migrator, storage) = try makeMigrator(uniqueId: "acc-exhaust")
        let engine = FakeZcashMigrationEngine(executeResults: [
            .networkError(retryable: true), .networkError(retryable: true), .networkError(retryable: true),
        ])
        migrator.engine = engine

        var thrown = false
        do {
            _ = try await migrator.performMigration(currentEndpointHost: "zec.rocks")
        } catch {
            thrown = true
        }

        #expect(thrown)
        #expect(engine.executeResults.isEmpty) // initial attempt + 2 retries consumed the queue
        let storedIds = try storage.migrationTxIds(accountId: "acc-exhaust")
        #expect(storedIds.isEmpty)
        #expect(migrator.timestamp == nil)
    }

    @Test func nonRetryableNetworkErrorFailsImmediately() async throws {
        let (migrator, _) = try makeMigrator()
        let engine = FakeZcashMigrationEngine(executeResults: [.networkError(retryable: false), .networkError(retryable: false)])
        migrator.engine = engine

        var thrown = false
        do {
            _ = try await migrator.performMigration(currentEndpointHost: "zec.rocks")
        } catch {
            thrown = true
        }

        #expect(thrown)
        #expect(engine.executeResults.count == 1) // only the first result consumed, no retry
    }

    @Test func invalidNoteRestartsSchedule() async throws {
        let (migrator, _) = try makeMigrator()
        let engine = FakeZcashMigrationEngine(executeResults: [.invalidNote])
        migrator.engine = engine

        var thrown = false
        do {
            _ = try await migrator.performMigration(currentEndpointHost: "zec.rocks")
        } catch {
            thrown = true
        }

        #expect(thrown)
        #expect(engine.signedSchedule == nil) // restart cleared the schedule
    }

    @Test func dustBalanceThrowsNotEnough() async throws {
        let (migrator, _) = try makeMigrator()
        migrator.engine = FakeZcashMigrationEngine(orchardSpendable: Zatoshi(10000)) // below fake fee

        var notEnough = false
        do {
            _ = try await migrator.performMigration(currentEndpointHost: "zec.rocks")
        } catch AppError.ZcashError.notEnough {
            notEnough = true
        }

        #expect(notEnough)
    }

    @Test func proposalAmountAndFee() async throws {
        let (migrator, _) = try makeMigrator()
        migrator.engine = FakeZcashMigrationEngine(orchardSpendable: Zatoshi(100_000_000))

        let proposal = try await migrator.migrationProposal(orchardBalance: 1)

        #expect(proposal.amount == (Zatoshi(100_000_000) - Self.fee).decimalValue.decimalValue)
        #expect(proposal.fee == 1 - proposal.amount)
    }

    // MARK: - Reconciliation

    @Test func reconcileDeliversSignedPendingTransfer() async throws {
        let (migrator, storage) = try makeMigrator(uniqueId: "acc-rec")
        let engine = FakeZcashMigrationEngine()
        migrator.engine = engine

        // interrupted session: signed but never executed
        let schedule = try await engine.proposeImmediate()
        try await engine.signAndStore(schedule: schedule)

        await migrator.reconcileIfNeeded(currentEndpointHost: "zec.rocks")

        #expect(engine.executedTxIds.count == 1)
        let storedIds = try storage.migrationTxIds(accountId: "acc-rec")
        #expect(storedIds == engine.executedTxIds)
    }

    @Test func reconcileIsNoOpWhenNothingPending() async throws {
        let (migrator, storage) = try makeMigrator(uniqueId: "acc-idle")
        let engine = FakeZcashMigrationEngine()
        migrator.engine = engine

        await migrator.reconcileIfNeeded(currentEndpointHost: "zec.rocks")

        #expect(engine.executedTxIds.isEmpty)
        let storedIds = try storage.migrationTxIds(accountId: "acc-idle")
        #expect(storedIds.isEmpty)
    }

    // MARK: - Broadcast endpoint

    @Test func submissionEndpointAvoidsSyncNode() throws {
        let (migrator, _) = try makeMigrator(networkType: .mainnet)

        let endpoint = migrator.submissionEndpoint(excludingHost: ZcashNode.defaultNodes[0].url.host!)

        #expect(endpoint.host != ZcashNode.defaultNodes[0].url.host)
        let isDefault = ZcashNode.defaultNodes.contains { $0.url.host == endpoint.host }
        #expect(isDefault)
    }

    @Test func submissionEndpointTestnetDegeneratesToSameNode() throws {
        let (migrator, _) = try makeMigrator(networkType: .testnet)

        let endpoint = migrator.submissionEndpoint(excludingHost: ZcashNode.defaultTestnetNodes[0].url.host!)

        #expect(endpoint.host == ZcashNode.defaultTestnetNodes[0].url.host)
    }

    // MARK: - Wallet isolation

    @Test func recordsAreIsolatedPerAccount() async throws {
        let storage = try makeStorage()
        let (migratorA, _) = try makeMigrator(uniqueId: "acc-a", storage: storage)
        let (migratorB, _) = try makeMigrator(uniqueId: "acc-b", storage: storage)
        migratorA.engine = FakeZcashMigrationEngine()

        _ = try await migratorA.performMigration(currentEndpointHost: "zec.rocks")

        #expect(migratorA.timestamp != nil)
        #expect(migratorB.timestamp == nil)
        let idsB = try storage.migrationTxIds(accountId: "acc-b")
        #expect(idsB.isEmpty)

        migratorB.clearOnWipe()
        let idsA = try storage.migrationTxIds(accountId: "acc-a")
        #expect(idsA.count == 1) // wiping B must not touch A

        migratorA.clearOnWipe()
        #expect(migratorA.timestamp == nil)
    }
}

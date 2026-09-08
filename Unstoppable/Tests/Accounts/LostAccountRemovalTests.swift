import Foundation
import GRDB
import Testing
@testable import WalletCore

struct LostAccountRemovalTests {
    @Test func removingMigratedRecordPreservesRestoredWalletWithSameName() throws {
        let env = try Environment()
        let cache = env.cache()
        let activeId = cache.activeAccount?.id

        try cache.removeLostAccounts(ids: ["lost", "restored", "unknown"])

        #expect(Set(env.records.all.map(\.id)) == ["restored", "other-lost"])
        #expect(cache.lostAccountRecords.map(\.id) == ["other-lost"])
        #expect(cache.allAccounts.map(\.id) == ["restored"])
        #expect(cache.activeAccount?.id == activeId)
        // Rebuild from the database, as on a cold launch.
        #expect(env.cache().lostAccountRecords.map(\.id) == ["other-lost"])
    }

    @Test func openingAndDismissingWithoutRemovalPreservesRecords() throws {
        let env = try Environment()
        _ = env.cache().lostAccountRecords

        #expect(Set(env.cache().lostAccountRecords.map(\.id)) == ["lost", "other-lost"])
        #expect(env.records.all.count == 3)
    }

    @Test func removingAllLostRecordsIsPersistentAndIdempotent() throws {
        let env = try Environment()
        let cache = env.cache()

        try cache.removeLostAccounts(ids: ["lost", "other-lost"])
        try cache.removeLostAccounts(ids: ["lost", "other-lost"])

        #expect(cache.lostAccountRecords.isEmpty)
        #expect(env.cache().lostAccountRecords.isEmpty)
        #expect(env.records.all.map(\.id) == ["restored"])
    }

    @Test func failedDatabaseDeletePreservesSnapshotAndRows() throws {
        let env = try Environment()
        let cache = env.cache()
        try env.pool.write { db in
            try db.execute(sql: """
                CREATE TRIGGER reject_lost_delete BEFORE DELETE ON account_records
                WHEN OLD.id = 'other-lost'
                BEGIN SELECT RAISE(ABORT, 'simulated storage failure'); END;
                """)
        }

        #expect(throws: DatabaseError.self) {
            try cache.removeLostAccounts(ids: ["lost", "other-lost"])
        }
        #expect(env.records.all.count == 3)
        #expect(Set(cache.lostAccountRecords.map(\.id)) == ["lost", "other-lost"])
        #expect(Set(env.cache().lostAccountRecords.map(\.id)) == ["lost", "other-lost"])
    }

    @Test func currentPasscodeLevelLimitsRemovalEvenForPreviouslyDisplayedIds() throws {
        let env = try Environment()
        let cache = env.cache()
        let previouslyDisplayedIds = Set(cache.lostAccountRecords.map(\.id))
        cache.set(level: 1)

        #expect(cache.lostAccountRecords.map(\.id) == ["other-lost"])
        try cache.removeLostAccounts(ids: previouslyDisplayedIds)
        cache.set(level: 0)

        #expect(cache.lostAccountRecords.map(\.id) == ["lost"])
        #expect(Set(env.records.all.map(\.id)) == ["lost", "restored"])
    }

    @Test func recordReconstructedSinceLaunchCannotBeRemovedAsLost() throws {
        let env = try Environment()
        let cache = env.cache()
        cache.save(account: account(id: "lost"))

        try cache.removeLostAccounts(ids: ["lost"])

        #expect(env.records.all.count == 3)
        #expect(cache.account(id: "lost") != nil)
    }

    @Test func clearingAccountsAlsoClearsLostSnapshot() throws {
        let env = try Environment()
        let cache = env.cache()
        cache.clear()

        #expect(cache.lostAccountRecords.isEmpty)
        #expect(env.records.all.isEmpty)
        #expect(env.cache().lostAccountRecords.isEmpty)
    }
}

private func account(id: String) -> Account {
    Account(id: id, level: 0, name: "Same display name", type: .mnemonic(words: ["synthetic-test-fixture"], salt: "", bip39Compliant: true), origin: .restored, backedUp: true, fileBackedUp: false)
}

private final class Environment {
    let pool: DatabasePool
    let records: AccountRecordStorage
    let source: Source
    private let directory: URL

    init() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("lost-account-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        pool = try DatabasePool(path: directory.appendingPathComponent("bank.sqlite").path)
        try pool.write { db in
            try db.create(table: AccountRecord.databaseTableName) { t in
                t.column("id", .text).primaryKey(onConflict: .replace)
                t.column("level", .integer).notNull()
                for column in ["name", "type", "origin"] {
                    t.column(column, .text).notNull()
                }
                for column in ["backedUp", "fileBackedUp"] {
                    t.column(column, .boolean).notNull()
                }
                for column in ["wordsKey", "saltKey", "dataKey"] {
                    t.column(column, .text)
                }
                t.column("bip39Compliant", .boolean)
            }
            try db.create(table: ActiveAccount.databaseTableName) { t in
                t.column("level", .integer).primaryKey(onConflict: .replace)
                t.column("accountId", .text).notNull()
            }
        }
        records = AccountRecordStorage(dbPool: pool)
        source = Source(records: records)
        source.save(account: account(id: "restored"))
        for (id, level) in [("lost", 0), ("other-lost", 1)] {
            records.save(record: AccountRecord(id: id, level: level, name: "Same display name", type: "mnemonic", origin: "restored", backedUp: true, fileBackedUp: false, wordsKey: nil, saltKey: nil, dataKey: nil, bip39Compliant: true))
        }
    }

    deinit {
        try? pool.close()
        try? FileManager.default.removeItem(at: directory)
    }

    func cache() -> AccountCachedStorage {
        AccountCachedStorage(level: 0, accountStorage: source, activeAccountStorage: ActiveAccountStorage(dbPool: pool))
    }
}

// Inject unreadable/readable classification without touching the test host's Keychain.
// Actual record deletion and cold-cache reconstruction still use a real SQLite database.
private final class Source: IAccountStorage {
    let records: AccountRecordStorage
    private var readableAccounts = [String: Account]()

    init(records: AccountRecordStorage) {
        self.records = records
    }

    var allAccounts: ([Account], [AccountRecord]) {
        let all = records.all
        return (all.compactMap { readableAccounts[$0.id] }, all.filter { readableAccounts[$0.id] == nil })
    }

    func save(account: Account) {
        records.save(record: AccountRecord(id: account.id, level: account.level, name: account.name, type: "mnemonic", origin: "restored", backedUp: true, fileBackedUp: false, wordsKey: nil, saltKey: nil, dataKey: nil, bip39Compliant: true))
        readableAccounts[account.id] = account
    }

    func delete(account: Account) {
        records.delete(by: account.id)
        readableAccounts.removeValue(forKey: account.id)
    }

    func delete(accountIds: Set<String>) throws {
        try records.delete(by: accountIds)
    }

    func clear() {
        records.clear()
        readableAccounts = [:]
    }
}

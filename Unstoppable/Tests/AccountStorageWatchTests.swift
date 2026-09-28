import Foundation
import GRDB
import HsToolKit
import Testing
@testable import WalletCore

// THORChain and Maya watch accounts survive a restart: saved by one AccountStorage, read back by a new one on the
// same database. They keep the address in the record itself, so the keychain is never touched.
struct AccountStorageWatchTests {
    @Test func thorChainAndMayaWatchAccountsSurviveRestart() throws {
        let dbPool = try Self.dbPool()
        let thor = Self.account(id: "thor-watch", type: .thorChainAddress(address: "thor1le9eykyndunax8k24w8fykd8ndx35w2h27c008"))
        let maya = Self.account(id: "maya-watch", type: .mayaChainAddress(address: "maya1le9eykyndunax8k24w8fykd8ndx35w2h2fxreh"))

        let storage = Self.storage(dbPool: dbPool)
        storage.save(account: thor)
        storage.save(account: maya)

        let (accounts, lostRecords) = Self.storage(dbPool: dbPool).allAccounts

        #expect(lostRecords.isEmpty)
        #expect(accounts.first { $0.id == thor.id }?.type == thor.type)
        #expect(accounts.first { $0.id == maya.id }?.type == maya.type)
    }
}

extension AccountStorageWatchTests {
    private static func storage(dbPool: DatabasePool) -> AccountStorage {
        AccountStorage(
            keychainStorage: KeychainStorage(service: "account-storage-watch-tests", logger: Logger(minLogLevel: .error)),
            storage: AccountRecordStorage(dbPool: dbPool)
        )
    }

    // The table as StorageMigrator leaves it; the migrator itself touches the app keychain, so it is not run here
    private static func dbPool() throws -> DatabasePool {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("account-storage-watch-tests-\(UUID().uuidString).sqlite").path
        let dbPool = try DatabasePool(path: path)

        try dbPool.write { db in
            try db.create(table: AccountRecord.databaseTableName) { t in
                t.column(AccountRecord.Columns.id.name, .text).notNull().primaryKey()
                t.column(AccountRecord.Columns.level.name, .integer).notNull()
                t.column(AccountRecord.Columns.name.name, .text).notNull()
                t.column(AccountRecord.Columns.type.name, .text).notNull()
                t.column(AccountRecord.Columns.origin.name, .text).notNull()
                t.column(AccountRecord.Columns.backedUp.name, .boolean).notNull()
                t.column(AccountRecord.Columns.fileBackedUp.name, .boolean).notNull()
                t.column(AccountRecord.Columns.wordsKey.name, .text)
                t.column(AccountRecord.Columns.saltKey.name, .text)
                t.column(AccountRecord.Columns.dataKey.name, .text)
                t.column(AccountRecord.Columns.bip39Compliant.name, .boolean)
            }
        }

        return dbPool
    }

    private static func account(id: String, type: AccountType) -> Account {
        Account(id: id, level: 0, name: id, type: type, origin: .restored, backedUp: true, fileBackedUp: false)
    }
}

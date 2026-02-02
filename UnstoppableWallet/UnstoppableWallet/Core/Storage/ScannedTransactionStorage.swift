import Foundation
import GRDB

class ScannedTransactionStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) throws {
        self.dbPool = dbPool
        try migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("create ScannedTransaction") { db in
            try db.create(table: ScannedTransaction.databaseTableName) { t in
                t.column(ScannedTransaction.Columns.transactionHash.name, .blob).notNull().primaryKey()
                t.column(ScannedTransaction.Columns.blockchainTypeUid.name, .text).notNull()
                t.column(ScannedTransaction.Columns.isSpam.name, .boolean).notNull()
                t.column(ScannedTransaction.Columns.spamAddress.name, .text)
            }

            try db.create(
                index: "scannedTransactions_spamAddress",
                on: ScannedTransaction.databaseTableName,
                columns: [ScannedTransaction.Columns.spamAddress.name]
            )
        }

        migrator.registerMigration("create SpamScanState") { db in
            try db.create(table: SpamScanState.databaseTableName) { t in
                t.column(SpamScanState.Columns.blockchainTypeUid.name, .text).notNull()
                t.column(SpamScanState.Columns.accountUid.name, .text).notNull()
                t.column(SpamScanState.Columns.lastPaginationData.name, .text).notNull()

                t.primaryKey(
                    [SpamScanState.Columns.blockchainTypeUid.name, SpamScanState.Columns.accountUid.name],
                    onConflict: .replace
                )
            }
        }

        migrator.registerMigration("create OutgoingAddress") { db in
            try db.create(table: OutgoingAddress.databaseTableName) { t in
                t.column(OutgoingAddress.Columns.address.name, .text).notNull()
                t.column(OutgoingAddress.Columns.blockchainTypeUid.name, .text).notNull()
                t.column(OutgoingAddress.Columns.accountUid.name, .text).notNull()
                t.column(OutgoingAddress.Columns.timestamp.name, .integer).notNull()
                t.column(OutgoingAddress.Columns.blockHeight.name, .integer)

                t.primaryKey(
                    [OutgoingAddress.Columns.address.name,
                     OutgoingAddress.Columns.blockchainTypeUid.name,
                     OutgoingAddress.Columns.accountUid.name],
                    onConflict: .replace
                )
            }

            try db.create(
                index: "outgoingAddresses_lookup",
                on: OutgoingAddress.databaseTableName,
                columns: [
                    OutgoingAddress.Columns.blockchainTypeUid.name,
                    OutgoingAddress.Columns.accountUid.name,
                    OutgoingAddress.Columns.timestamp.name,
                ]
            )
        }

        return migrator
    }
}

// MARK: - ScannedTransaction

extension ScannedTransactionStorage {
    func save(scannedTransaction: ScannedTransaction) throws {
        try dbPool.write { db in
            try scannedTransaction.save(db)
        }
    }

    func save(scannedTransactions: [ScannedTransaction]) throws {
        try dbPool.write { db in
            for transaction in scannedTransactions {
                try transaction.save(db)
            }
        }
    }

    func findScanned(transactionHash: Data) throws -> ScannedTransaction? {
        try dbPool.read { db in
            try ScannedTransaction
                .filter(ScannedTransaction.Columns.transactionHash == transactionHash)
                .fetchOne(db)
        }
    }

    func findScanned(address: String) throws -> ScannedTransaction? {
        try dbPool.read { db in
            try ScannedTransaction
                .filter(ScannedTransaction.Columns.spamAddress == address)
                .filter(ScannedTransaction.Columns.isSpam == true)
                .fetchOne(db)
        }
    }

    func isSpam(transactionHash: Data) throws -> Bool {
        try dbPool.read { db in
            try ScannedTransaction
                .filter(ScannedTransaction.Columns.transactionHash == transactionHash)
                .filter(ScannedTransaction.Columns.isSpam == true)
                .fetchOne(db) != nil
        }
    }

    func allSpamAddresses(blockchainTypeUid: String) throws -> [String] {
        try dbPool.read { db in
            try ScannedTransaction
                .filter(ScannedTransaction.Columns.blockchainTypeUid == blockchainTypeUid)
                .filter(ScannedTransaction.Columns.isSpam == true)
                .filter(ScannedTransaction.Columns.spamAddress != nil)
                .select(ScannedTransaction.Columns.spamAddress, as: String.self)
                .fetchAll(db)
        }
    }

    func clearScannedTransactions() throws {
        _ = try dbPool.write { db in
            try ScannedTransaction.deleteAll(db)
        }
    }

    func clearScannedTransactions(blockchainTypeUid: String) throws {
        _ = try dbPool.write { db in
            try ScannedTransaction
                .filter(ScannedTransaction.Columns.blockchainTypeUid == blockchainTypeUid)
                .deleteAll(db)
        }
    }
}

// MARK: - SpamScanState

extension ScannedTransactionStorage {
    func save(spamScanState: SpamScanState) throws {
        try dbPool.write { db in
            try spamScanState.save(db)
        }
    }

    func find(blockchainTypeUid: String, accountUid: String) throws -> SpamScanState? {
        try dbPool.read { db in
            try SpamScanState
                .filter(SpamScanState.Columns.blockchainTypeUid == blockchainTypeUid)
                .filter(SpamScanState.Columns.accountUid == accountUid)
                .fetchOne(db)
        }
    }

    func clearScanStates() throws {
        _ = try dbPool.write { db in
            try SpamScanState.deleteAll(db)
        }
    }

    func clearScanState(blockchainTypeUid: String, accountUid: String) throws {
        _ = try dbPool.write { db in
            try SpamScanState
                .filter(SpamScanState.Columns.blockchainTypeUid == blockchainTypeUid)
                .filter(SpamScanState.Columns.accountUid == accountUid)
                .deleteAll(db)
        }
    }
}

// MARK: - OutgoingAddress

extension ScannedTransactionStorage {
    func save(outgoingAddresses: [OutgoingAddress]) throws {
        guard !outgoingAddresses.isEmpty else { return }
        try dbPool.write { db in
            for address in outgoingAddresses {
                try address.save(db)
            }
        }
    }

    func loadOutgoingAddresses(blockchainTypeUid: String, accountUid: String, limit: Int) throws -> [OutgoingAddress] {
        try dbPool.read { db in
            try OutgoingAddress
                .filter(OutgoingAddress.Columns.blockchainTypeUid == blockchainTypeUid)
                .filter(OutgoingAddress.Columns.accountUid == accountUid)
                .order(OutgoingAddress.Columns.timestamp.desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    func clearOutgoingAddresses() throws {
        _ = try dbPool.write { db in
            try OutgoingAddress.deleteAll(db)
        }
    }

    func clearOutgoingAddresses(blockchainTypeUid: String, accountUid: String) throws {
        _ = try dbPool.write { db in
            try OutgoingAddress
                .filter(OutgoingAddress.Columns.blockchainTypeUid == blockchainTypeUid)
                .filter(OutgoingAddress.Columns.accountUid == accountUid)
                .deleteAll(db)
        }
    }
}

// MARK: - Clear All

extension ScannedTransactionStorage {
    func clearAll() throws {
        try dbPool.write { db in
            try ScannedTransaction.deleteAll(db)
            try SpamScanState.deleteAll(db)
            try OutgoingAddress.deleteAll(db)
        }
    }
}

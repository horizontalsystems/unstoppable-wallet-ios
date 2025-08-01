import Foundation
import GRDB

class MerkleTransactionHashStorage {
    private let dbPool: DatabasePool

    init(databaseDirectoryUrl: URL, databaseFileName: String) {
        let databaseURL = databaseDirectoryUrl.appendingPathComponent("\(databaseFileName).sqlite")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try? migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("create MerkleTransactionHash") { db in
            try db.create(table: MerkleTransactionHash.databaseTableName) { t in
                t.column(MerkleTransactionHash.Columns.transactionHash.name, .blob).primaryKey(onConflict: .replace)
            }
        }

        return migrator
    }
}

extension MerkleTransactionHashStorage {
    func hashes() throws -> [MerkleTransactionHash] {
        try dbPool.read { db in
            try MerkleTransactionHash.fetchAll(db)
        }
    }

    func save(hash: MerkleTransactionHash) throws {
        try dbPool.write { db in
            try hash.save(db)
        }
    }

    @discardableResult func delete(hash: MerkleTransactionHash) throws -> Bool {
        try dbPool.write { db in
            try MerkleTransactionHash
                .filter(MerkleTransactionHash.Columns.transactionHash == hash.transactionHash)
                .deleteAll(db) > 0
        }
    }

    @discardableResult func delete(hashes: [MerkleTransactionHash]) throws -> Int {
        guard !hashes.isEmpty else { return 0 }
        let count = try dbPool.write { db in
            let keys = hashes.map(\.transactionHash)
            return try MerkleTransactionHash.deleteAll(db, keys: keys)
        }
        return count
    }
}

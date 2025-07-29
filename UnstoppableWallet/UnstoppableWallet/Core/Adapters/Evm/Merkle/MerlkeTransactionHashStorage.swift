import Foundation
import GRDB

class MerkleTransactionHashStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }
}

extension MerkleTransactionHashStorage {
    func hashes(chainId: Int) throws -> [MerkleTransactionHash] {
        try dbPool.read { db in
            try MerkleTransactionHash.filter(MerkleTransactionHash.Columns.chainId == chainId).fetchAll(db)
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
                .filter(MerkleTransactionHash.Columns.chainId == hash.chainId && MerkleTransactionHash.Columns.transactionHash == hash.transactionHash)
                .deleteAll(db) > 0
        }
    }
    
    private func mapKey(hash: MerkleTransactionHash) -> [String: any DatabaseValueConvertible] {
        [
            MerkleTransactionHash.Columns.transactionHash.name: hash.transactionHash,
            MerkleTransactionHash.Columns.chainId.name: hash.chainId
        ]
    }

    @discardableResult func delete(hashes: [MerkleTransactionHash]) throws -> Int {
        guard !hashes.isEmpty else { return 0 }
        let count = try dbPool.write { db in
            let keys = hashes.map { mapKey(hash: $0) }
            return try MerkleTransactionHash.deleteAll(db, keys: keys)
        }
        return count
    }
}

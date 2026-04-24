import Foundation
import GRDB

class PendingUserOperationRecordStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }
}

extension PendingUserOperationRecordStorage {
    func all() throws -> [PendingUserOperationRecord] {
        try dbPool.read { db in
            try PendingUserOperationRecord.fetchAll(db)
        }
    }

    func pendingOperations(status: String) throws -> [PendingUserOperationRecord] {
        try dbPool.read { db in
            try PendingUserOperationRecord
                .filter(PendingUserOperationRecord.Columns.status == status)
                .fetchAll(db)
        }
    }

    func operation(userOpHash: String) throws -> PendingUserOperationRecord? {
        try dbPool.read { db in
            try PendingUserOperationRecord
                .filter(PendingUserOperationRecord.Columns.userOpHash == userOpHash)
                .fetchOne(db)
        }
    }

    func save(record: PendingUserOperationRecord) throws {
        try dbPool.write { db in
            try record.insert(db)
        }
    }

    func update(userOpHash: String, status: String, txHash: String?, lastPolledAt: TimeInterval?) throws {
        try dbPool.write { db in
            try PendingUserOperationRecord
                .filter(PendingUserOperationRecord.Columns.userOpHash == userOpHash)
                .updateAll(
                    db,
                    PendingUserOperationRecord.Columns.status.set(to: status),
                    PendingUserOperationRecord.Columns.txHash.set(to: txHash),
                    PendingUserOperationRecord.Columns.lastPolledAt.set(to: lastPolledAt)
                )
        }
    }

    func delete(userOpHash: String) throws {
        try dbPool.write { db in
            try PendingUserOperationRecord
                .filter(PendingUserOperationRecord.Columns.userOpHash == userOpHash)
                .deleteAll(db)
        }
    }

    func clear() throws {
        try dbPool.write { db in
            try PendingUserOperationRecord.deleteAll(db)
        }
    }
}

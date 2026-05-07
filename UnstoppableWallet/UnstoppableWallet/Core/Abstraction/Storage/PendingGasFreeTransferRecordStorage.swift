import Foundation
import GRDB

class PendingGasFreeTransferRecordStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }
}

extension PendingGasFreeTransferRecordStorage {
    func all() throws -> [PendingGasFreeTransferRecord] {
        try dbPool.read { db in
            try PendingGasFreeTransferRecord.fetchAll(db)
        }
    }

    func transfers(status: String) throws -> [PendingGasFreeTransferRecord] {
        try dbPool.read { db in
            try PendingGasFreeTransferRecord
                .filter(PendingGasFreeTransferRecord.Columns.status == status)
                .fetchAll(db)
        }
    }

    func transfer(traceId: String) throws -> PendingGasFreeTransferRecord? {
        try dbPool.read { db in
            try PendingGasFreeTransferRecord
                .filter(PendingGasFreeTransferRecord.Columns.traceId == traceId)
                .fetchOne(db)
        }
    }

    func save(record: PendingGasFreeTransferRecord) throws {
        try dbPool.write { db in
            try record.insert(db)
        }
    }

    func update(traceId: String, status: String, txnHash: String?, lastPolledAt: TimeInterval?) throws {
        try dbPool.write { db in
            try PendingGasFreeTransferRecord
                .filter(PendingGasFreeTransferRecord.Columns.traceId == traceId)
                .updateAll(
                    db,
                    PendingGasFreeTransferRecord.Columns.status.set(to: status),
                    PendingGasFreeTransferRecord.Columns.txnHash.set(to: txnHash),
                    PendingGasFreeTransferRecord.Columns.lastPolledAt.set(to: lastPolledAt)
                )
        }
    }

    func delete(traceId: String) throws {
        try dbPool.write { db in
            try PendingGasFreeTransferRecord
                .filter(PendingGasFreeTransferRecord.Columns.traceId == traceId)
                .deleteAll(db)
        }
    }

    func clear() throws {
        try dbPool.write { db in
            try PendingGasFreeTransferRecord.deleteAll(db)
        }
    }
}

import GRDB

class CexAssetRecordStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

}

extension CexAssetRecordStorage {

    func balanceAssets(accountId: String) throws -> [CexAssetRecord] {
        try dbPool.read { db in
            try CexAssetRecord
                    .filter(CexAssetRecord.Columns.accountId == accountId && (CexAssetRecord.Columns.freeBalance != 0 || CexAssetRecord.Columns.lockedBalance != 0))
                    .fetchAll(db)
        }
    }

    func assets(accountId: String) throws -> [CexAssetRecord] {
        try dbPool.read { db in
            try CexAssetRecord.filter(CexAssetRecord.Columns.accountId == accountId).fetchAll(db)
        }
    }

    func resave(records: [CexAssetRecord], accountId: String) throws {
        _ = try dbPool.write { db in
            try CexAssetRecord.filter(CexAssetRecord.Columns.accountId == accountId).deleteAll(db)

            for record in records {
                try record.insert(db)
            }
        }
    }

    func clear(accountId: String) throws {
        _ = try dbPool.write { db in
            try CexAssetRecord.filter(CexAssetRecord.Columns.accountId == accountId).deleteAll(db)
        }
    }

}

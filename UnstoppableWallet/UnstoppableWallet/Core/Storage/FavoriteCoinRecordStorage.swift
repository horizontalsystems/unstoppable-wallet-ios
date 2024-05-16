import GRDB

class FavoriteCoinRecordStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }
}

extension FavoriteCoinRecordStorage {
    func favoriteCoinRecords() throws -> [FavoriteCoinRecord] {
        try dbPool.read { db in
            try FavoriteCoinRecord.fetchAll(db)
        }
    }

    func save(favoriteCoinRecord: FavoriteCoinRecord) throws {
        _ = try dbPool.write { db in
            try favoriteCoinRecord.insert(db)
        }
    }

    func save(favoriteCoinRecords: [FavoriteCoinRecord]) throws {
        _ = try dbPool.write { db in
            for record in favoriteCoinRecords {
                try record.insert(db)
            }
        }
    }

    func deleteAll() throws {
        _ = try dbPool.write { db in
            try FavoriteCoinRecord
                .deleteAll(db)
        }
    }

    func deleteFavoriteCoinRecord(coinUid: String) throws {
        _ = try dbPool.write { db in
            try FavoriteCoinRecord
                .filter(FavoriteCoinRecord.Columns.coinUid == coinUid)
                .deleteAll(db)
        }
    }

    func favoriteCoinRecordExists(coinUid: String) throws -> Bool {
        try dbPool.read { db in
            try FavoriteCoinRecord
                .filter(FavoriteCoinRecord.Columns.coinUid == coinUid)
                .fetchCount(db) > 0
        }
    }
}

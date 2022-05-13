import GRDB

class FavoriteCoinRecordStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

}

extension FavoriteCoinRecordStorage {

    var favoriteCoinRecords: [FavoriteCoinRecord] {
        try! dbPool.read { db in
            try FavoriteCoinRecord.fetchAll(db)
        }
    }

    func save(favoriteCoinRecord: FavoriteCoinRecord) {
        _ = try! dbPool.write { db in
            try favoriteCoinRecord.insert(db)
        }
    }

    func save(favoriteCoinRecords: [FavoriteCoinRecord]) {
        _ = try! dbPool.write { db in
            for record in favoriteCoinRecords {
                try record.insert(db)
            }
        }
    }

    func deleteFavoriteCoinRecord(coinUid: String) {
        _ = try! dbPool.write { db in
            try FavoriteCoinRecord
                    .filter(FavoriteCoinRecord.Columns.coinUid == coinUid)
                    .deleteAll(db)
        }
    }

    func favoriteCoinRecordExists(coinUid: String) -> Bool {
        try! dbPool.read { db in
            try FavoriteCoinRecord
                    .filter(FavoriteCoinRecord.Columns.coinUid == coinUid)
                    .fetchCount(db) > 0
        }
    }

    var favoriteCoinRecords_v_0_22: [FavoriteCoinRecord_v_0_22] {
        try! dbPool.read { db in
            try FavoriteCoinRecord_v_0_22.fetchAll(db)
        }
    }

}

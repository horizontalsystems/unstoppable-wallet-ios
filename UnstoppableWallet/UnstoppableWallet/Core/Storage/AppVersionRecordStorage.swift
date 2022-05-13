import GRDB

class AppVersionRecordStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

}

extension AppVersionRecordStorage {

    var appVersionRecords: [AppVersionRecord] {
        try! dbPool.read { db in
            try AppVersionRecord.fetchAll(db)
        }
    }

    func save(appVersionRecords: [AppVersionRecord]) {
        _ = try! dbPool.write { db in
            for record in appVersionRecords {
                try record.insert(db)
            }
        }
    }

}

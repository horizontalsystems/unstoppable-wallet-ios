import GRDB

class RestoreSettingsStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

}

extension RestoreSettingsStorage {

    func restoreSettings(accountId: String, blockchainUid: String) -> [RestoreSettingRecord] {
        try! dbPool.read { db in
            try RestoreSettingRecord.filter(RestoreSettingRecord.Columns.accountId == accountId && RestoreSettingRecord.Columns.blockchainUid == blockchainUid).fetchAll(db)
        }
    }

    func restoreSettings(accountId: String) -> [RestoreSettingRecord] {
        try! dbPool.read { db in
            try RestoreSettingRecord.filter(RestoreSettingRecord.Columns.accountId == accountId).fetchAll(db)
        }
    }

    func save(restoreSettingRecords: [RestoreSettingRecord]) {
        _ = try! dbPool.write { db in
            for record in restoreSettingRecords {
                try record.insert(db)
            }
        }
    }

    func deleteAllRestoreSettings(accountId: String) {
        _ = try! dbPool.write { db in
            try RestoreSettingRecord.filter(RestoreSettingRecord.Columns.accountId == accountId).deleteAll(db)
        }
    }

}

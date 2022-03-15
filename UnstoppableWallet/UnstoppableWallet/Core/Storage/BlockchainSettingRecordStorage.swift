import Foundation
import GRDB

class BlockchainSettingRecordStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) throws {
        self.dbPool = dbPool
    }

}

extension BlockchainSettingRecordStorage {

    func record(blockchainUid: String, key: String) throws -> BlockchainSettingRecord? {
        try dbPool.read { db in
            try BlockchainSettingRecord.filter(BlockchainSettingRecord.Columns.blockchainUid == blockchainUid && BlockchainSettingRecord.Columns.key == key).fetchOne(db)
        }
    }

    func save(record: BlockchainSettingRecord) throws {
        _ = try dbPool.write { db in
            try record.insert(db)
        }
    }

}

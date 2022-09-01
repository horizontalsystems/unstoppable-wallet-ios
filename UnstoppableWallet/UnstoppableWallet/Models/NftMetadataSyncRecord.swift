import Foundation
import GRDB

class NftMetadataSyncRecord: Record {
    let blockchainTypeUid: String
    let accountId: String
    let lastSyncTimestamp: TimeInterval

    init(blockchainTypeUid: String, accountId: String, lastSyncTimestamp: TimeInterval) {
        self.blockchainTypeUid = blockchainTypeUid
        self.accountId = accountId
        self.lastSyncTimestamp = lastSyncTimestamp

        super.init()
    }

    override class var databaseTableName: String {
        "nftMetadataSyncRecord"
    }

    enum Columns: String, ColumnExpression {
        case blockchainTypeUid
        case accountId
        case lastSyncTimestamp
    }

    required init(row: Row) {
        blockchainTypeUid = row[Columns.blockchainTypeUid]
        accountId = row[Columns.accountId]
        lastSyncTimestamp = row[Columns.lastSyncTimestamp]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.blockchainTypeUid] = blockchainTypeUid
        container[Columns.accountId] = accountId
        container[Columns.lastSyncTimestamp] = lastSyncTimestamp
    }

}

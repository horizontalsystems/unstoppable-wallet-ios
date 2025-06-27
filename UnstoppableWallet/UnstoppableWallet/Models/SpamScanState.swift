import Foundation
import GRDB
import MarketKit

public class SpamScanState: Record {
    let blockchainTypeUid: String
    let accountUid: String
    let lastPaginationData: String

    init(blockchainTypeUid: String, accountUid: String, lastPaginationData: String) {
        self.blockchainTypeUid = blockchainTypeUid
        self.accountUid = accountUid
        self.lastPaginationData = lastPaginationData

        super.init()
    }

    override public class var databaseTableName: String {
        "spamScanStates"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case blockchainTypeUid
        case accountUid
        case lastPaginationData
    }

    required init(row: Row) throws {
        blockchainTypeUid = row[Columns.blockchainTypeUid]
        accountUid = row[Columns.accountUid]
        lastPaginationData = row[Columns.lastPaginationData]

        try super.init(row: row)
    }

    override public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.blockchainTypeUid] = blockchainTypeUid
        container[Columns.accountUid] = accountUid
        container[Columns.lastPaginationData] = lastPaginationData
    }
}

import Foundation
import GRDB
import MarketKit

public class SpamScanState: Record {
    let blockchainTypeUid: String
    let accountUid: String
    let lastTransactionHash: Data

    init(blockchainTypeUid: String, accountUid: String, lastTransactionHash: Data) {
        self.blockchainTypeUid = blockchainTypeUid
        self.accountUid = accountUid
        self.lastTransactionHash = lastTransactionHash

        super.init()
    }

    override public class var databaseTableName: String {
        "spamScanStates"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case blockchainTypeUid
        case accountUid
        case lastTransactionHash
    }

    required init(row: Row) throws {
        blockchainTypeUid = row[Columns.blockchainTypeUid]
        accountUid = row[Columns.accountUid]
        lastTransactionHash = row[Columns.lastTransactionHash]

        try super.init(row: row)
    }

    override public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.blockchainTypeUid] = blockchainTypeUid
        container[Columns.accountUid] = accountUid
        container[Columns.lastTransactionHash] = lastTransactionHash
    }
}

import Foundation
import GRDB

public class ScannedTransaction: Record {
    let transactionHash: Data
    let blockchainTypeUid: String
    let isSpam: Bool
    let spamAddress: String?

    init(transactionHash: Data, blockchainTypeUid: String, isSpam: Bool, spamAddress: String?) {
        self.transactionHash = transactionHash
        self.blockchainTypeUid = blockchainTypeUid
        self.isSpam = isSpam
        self.spamAddress = spamAddress

        super.init()
    }

    override public class var databaseTableName: String {
        "scannedTransactions"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case transactionHash
        case blockchainTypeUid
        case isSpam
        case spamAddress
    }

    required init(row: Row) throws {
        transactionHash = row[Columns.transactionHash]
        blockchainTypeUid = row[Columns.blockchainTypeUid]
        isSpam = row[Columns.isSpam]
        spamAddress = row[Columns.spamAddress]

        try super.init(row: row)
    }

    override public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.transactionHash] = transactionHash
        container[Columns.blockchainTypeUid] = blockchainTypeUid
        container[Columns.isSpam] = isSpam
        container[Columns.spamAddress] = spamAddress
    }
}

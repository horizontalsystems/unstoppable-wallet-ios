import Foundation
import GRDB

class MerkleTransactionHash: Record {
    let transactionHash: Data

    init(transactionHash: Data) {
        self.transactionHash = transactionHash

        super.init()
    }

    override class var databaseTableName: String {
        "merkleTransactionHashes"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case transactionHash
    }

    required init(row: Row) throws {
        transactionHash = row[Columns.transactionHash]

        try super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) throws {
        container[Columns.transactionHash] = transactionHash
    }
}

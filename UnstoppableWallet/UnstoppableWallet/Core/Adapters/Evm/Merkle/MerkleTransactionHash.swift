import GRDB
import Foundation

class MerkleTransactionHash: Record {
    let transactionHash: Data
    let chainId: Int

    init(transactionHash: Data, chainId: Int) {
        self.transactionHash = transactionHash
        self.chainId = chainId

        super.init()
    }

    override public class var databaseTableName: String {
        "merkleTransactionHashes"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case transactionHash
        case chainId
    }

    required init(row: Row) throws {
        transactionHash = row[Columns.transactionHash]
        chainId = row[Columns.chainId]

        try super.init(row: row)
    }

    override public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.transactionHash] = transactionHash
        container[Columns.chainId] = chainId
    }
}

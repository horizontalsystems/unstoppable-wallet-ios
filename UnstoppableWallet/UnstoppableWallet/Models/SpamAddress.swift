import Foundation
import GRDB
import MarketKit

public class SpamAddress: Record {
    let transactionHash: Data
    let address: Address

    init(transactionHash: Data, address: Address) {
        self.transactionHash = transactionHash
        self.address = address

        super.init()
    }

    override public class var databaseTableName: String {
        "spamAddresses"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case transactionHash
        case raw
        case domain
        case blockchainTypeUid
    }

    required init(row: Row) throws {
        transactionHash = row[Columns.transactionHash]
        address = Address(raw: row[Columns.raw], domain: row[Columns.domain], blockchainType: BlockchainType(uid: row[Columns.blockchainTypeUid]))

        try super.init(row: row)
    }

    override public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.transactionHash] = transactionHash
        container[Columns.raw] = address.raw
        container[Columns.domain] = address.domain
        container[Columns.blockchainTypeUid] = address.blockchainType?.uid
    }
}

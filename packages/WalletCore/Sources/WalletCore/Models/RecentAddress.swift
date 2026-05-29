import Foundation
import GRDB

public class RecentAddress: Record {
    let blockchainUid: String
    let address: String

    init(blockchainUid: String, address: String) {
        self.blockchainUid = blockchainUid
        self.address = address

        super.init()
    }

    override public class var databaseTableName: String {
        "RecentAddress"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case blockchainUid
        case address
    }

    required init(row: Row) throws {
        blockchainUid = row[Columns.blockchainUid]
        address = row[Columns.address]

        try super.init(row: row)
    }

    override public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.blockchainUid] = blockchainUid
        container[Columns.address] = address
    }
}

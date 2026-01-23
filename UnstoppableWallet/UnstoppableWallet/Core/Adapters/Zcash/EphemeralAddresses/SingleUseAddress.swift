import Foundation
import GRDB

struct SingleUseAddress: Equatable {
    var rowId: Int64?
    let walletId: String
    let address: String
    let gapIndex: UInt32
    let gapLimit: UInt32
    let timestamp: Date
    var isUsed: Bool

    init(
        rowId: Int64? = nil,
        walletId: String,
        address: String,
        gapIndex: UInt32,
        gapLimit: UInt32,
        timestamp: Date = Date(),
        isUsed: Bool = false
    ) {
        self.rowId = rowId
        self.walletId = walletId
        self.address = address
        self.gapIndex = gapIndex
        self.gapLimit = gapLimit
        self.timestamp = timestamp
        self.isUsed = isUsed
    }

    mutating func markAsUsed() {
        isUsed = true
    }
}

extension SingleUseAddress: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "singleUseAddress"

    enum Columns: String, ColumnExpression {
        case rowId
        case walletId
        case address
        case gapIndex
        case gapLimit
        case timestamp
        case isUsed
    }

    init(row: Row) {
        rowId = row[Columns.rowId]
        walletId = row[Columns.walletId]
        address = row[Columns.address]
        gapIndex = row[Columns.gapIndex]
        gapLimit = row[Columns.gapLimit]
        timestamp = row[Columns.timestamp]
        isUsed = row[Columns.isUsed]
    }

    func encode(to container: inout PersistenceContainer) {
        container[Columns.rowId] = rowId
        container[Columns.walletId] = walletId
        container[Columns.address] = address
        container[Columns.gapIndex] = gapIndex
        container[Columns.gapLimit] = gapLimit
        container[Columns.timestamp] = timestamp
        container[Columns.isUsed] = isUsed
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        rowId = inserted.rowID
    }
}

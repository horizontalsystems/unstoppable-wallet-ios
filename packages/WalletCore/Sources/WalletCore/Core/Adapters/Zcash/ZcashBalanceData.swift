import Foundation
import GRDB

class ZcashBalanceData: Record, Equatable {
    static func empty(id: String) -> ZcashBalanceData {
        ZcashBalanceData(id: id, full: 0, available: 0, transparent: 0, orchard: 0)
    }

    let id: String
    let full: Decimal
    let available: Decimal
    let transparent: Decimal
    let orchard: Decimal

    init(id: String, full: Decimal, available: Decimal, transparent: Decimal, orchard: Decimal) {
        self.id = id
        self.full = full
        self.available = available
        self.transparent = transparent
        self.orchard = orchard

        super.init()
    }

    var balanceData: BalanceData {
        BalanceData(total: full + transparent, available: available)
    }

    override public class var databaseTableName: String {
        "zCashBalanceData"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case id
        case full
        case available
        case transparent
        case orchard
    }

    required init(row: Row) throws {
        id = row[Columns.id]
        full = row[Columns.full]
        available = row[Columns.available]
        transparent = row[Columns.transparent]
        orchard = row[Columns.orchard]

        try super.init(row: row)
    }

    override public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.full] = full
        container[Columns.available] = available
        container[Columns.transparent] = transparent
        container[Columns.orchard] = orchard
    }

    static func == (lhs: ZcashBalanceData, rhs: ZcashBalanceData) -> Bool {
        lhs.id == rhs.id &&
            lhs.full == rhs.full &&
            lhs.available == rhs.available &&
            lhs.transparent == rhs.transparent &&
            lhs.orchard == rhs.orchard
    }
}

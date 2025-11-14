import Foundation
import GRDB

class ZcashBalanceData: Record {
    static func empty(id: String) -> ZcashBalanceData {
        ZcashBalanceData(id: id, full: 0, available: 0, transparent: 0)
    }

    let id: String
    let full: Decimal
    let available: Decimal
    let transparent: Decimal

    init(id: String, full: Decimal, available: Decimal, transparent: Decimal) {
        self.id = id
        self.full = full
        self.available = available
        self.transparent = transparent

        super.init()
    }

    var balanceData: BalanceData {
        BalanceData(balance: full)
    }

    var processing: Decimal {
        full - available
    }

    override public class var databaseTableName: String {
        "zCashBalanceData"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case id
        case full
        case available
        case transparent
    }

    required init(row: Row) throws {
        id = row[Columns.id]
        full = row[Columns.full]
        available = row[Columns.available]
        transparent = row[Columns.transparent]

        try super.init(row: row)
    }

    override public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.full] = full
        container[Columns.available] = available
        container[Columns.transparent] = transparent
    }
}

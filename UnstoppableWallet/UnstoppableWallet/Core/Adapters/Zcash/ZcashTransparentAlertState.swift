import Foundation
import GRDB

struct ZcashTransparentAlertState: Equatable, FetchableRecord, PersistableRecord {
    let id: String
    var lastAlertedBalance: Decimal

    init(id: String, lastAlertedBalance: Decimal) {
        self.id = id
        self.lastAlertedBalance = lastAlertedBalance
    }

    static var databaseTableName: String { "zcashTransparentAlertState" }

    enum Columns: String, ColumnExpression, CaseIterable {
        case id
        case lastAlertedBalance
    }

    init(row: Row) throws {
        id = row[Columns.id]
        lastAlertedBalance = row[Columns.lastAlertedBalance]
    }

    func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.lastAlertedBalance] = lastAlertedBalance
    }
}

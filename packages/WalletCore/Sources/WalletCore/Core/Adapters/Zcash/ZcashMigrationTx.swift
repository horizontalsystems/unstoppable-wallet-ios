import Foundation
import GRDB

// txId is nil when the broadcast landed but the SDK failed to record the id (reconciled later);
// a row existing at all means a migration broadcast happened, createdAt is the privacy-buffer start
struct ZcashMigrationTx: Equatable, FetchableRecord, PersistableRecord {
    let txId: String?
    let accountId: String
    let createdAt: Date

    init(txId: String?, accountId: String, createdAt: Date) {
        self.txId = txId
        self.accountId = accountId
        self.createdAt = createdAt
    }

    static var databaseTableName: String { "zcashMigrationTx" }

    enum Columns: String, ColumnExpression, CaseIterable {
        case txId
        case accountId
        case createdAt
    }

    init(row: Row) throws {
        txId = row[Columns.txId]
        accountId = row[Columns.accountId]
        createdAt = row[Columns.createdAt]
    }

    func encode(to container: inout PersistenceContainer) {
        container[Columns.txId] = txId
        container[Columns.accountId] = accountId
        container[Columns.createdAt] = createdAt
    }
}

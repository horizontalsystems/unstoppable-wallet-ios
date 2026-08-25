import Foundation
import GRDB

struct ZcashTerminalResubmission: Equatable, FetchableRecord, PersistableRecord {
    enum Reason: String, DatabaseValueConvertible {
        case nodeRejected
    }

    let accountId: String
    let txId: String
    let network: String
    let reason: Reason
    let expiryHeight: Int

    init(accountId: String, txId: String, network: String, reason: Reason, expiryHeight: Int) {
        self.accountId = accountId
        self.txId = txId
        self.network = network
        self.reason = reason
        self.expiryHeight = expiryHeight
    }

    static var databaseTableName: String { "zcashTerminalResubmission" }

    enum Columns: String, ColumnExpression, CaseIterable {
        case accountId
        case txId
        case network
        case reason
        case expiryHeight
    }

    init(row: Row) throws {
        accountId = row[Columns.accountId]
        txId = row[Columns.txId]
        network = row[Columns.network]
        reason = row[Columns.reason]
        expiryHeight = row[Columns.expiryHeight]
    }

    func encode(to container: inout PersistenceContainer) {
        container[Columns.accountId] = accountId
        container[Columns.txId] = txId
        container[Columns.network] = network
        container[Columns.reason] = reason
        container[Columns.expiryHeight] = expiryHeight
    }
}

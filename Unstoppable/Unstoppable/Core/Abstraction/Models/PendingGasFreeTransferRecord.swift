import Foundation
import GRDB

class PendingGasFreeTransferRecord: Record {
    let traceId: String
    let accountId: String
    let token: String
    let value: String
    let receiver: String
    let txnHash: String?
    let status: String
    let submittedAt: TimeInterval
    let lastPolledAt: TimeInterval?

    init(
        traceId: String,
        accountId: String,
        token: String,
        value: String,
        receiver: String,
        txnHash: String?,
        status: String,
        submittedAt: TimeInterval,
        lastPolledAt: TimeInterval?
    ) {
        self.traceId = traceId
        self.accountId = accountId
        self.token = token
        self.value = value
        self.receiver = receiver
        self.txnHash = txnHash
        self.status = status
        self.submittedAt = submittedAt
        self.lastPolledAt = lastPolledAt

        super.init()
    }

    override class var databaseTableName: String {
        "pending_gas_free_transfers"
    }

    enum Columns: String, ColumnExpression {
        case traceId, accountId, token, value, receiver, txnHash, status, submittedAt, lastPolledAt
    }

    required init(row: Row) throws {
        traceId = row[Columns.traceId]
        accountId = row[Columns.accountId]
        token = row[Columns.token]
        value = row[Columns.value]
        receiver = row[Columns.receiver]
        txnHash = row[Columns.txnHash]
        status = row[Columns.status]
        submittedAt = row[Columns.submittedAt]
        lastPolledAt = row[Columns.lastPolledAt]

        try super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.traceId] = traceId
        container[Columns.accountId] = accountId
        container[Columns.token] = token
        container[Columns.value] = value
        container[Columns.receiver] = receiver
        container[Columns.txnHash] = txnHash
        container[Columns.status] = status
        container[Columns.submittedAt] = submittedAt
        container[Columns.lastPolledAt] = lastPolledAt
    }
}

extension PendingGasFreeTransferRecord {
    /// Domain view of the wire-format `status` column. Persisted as String for trivial
    /// GRDB serialization; consumers read this typed property.
    var state: GasFreeTransferState {
        GasFreeTransferState(rawString: status)
    }
}

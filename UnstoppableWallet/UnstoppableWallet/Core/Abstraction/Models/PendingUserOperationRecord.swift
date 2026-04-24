import Foundation
import GRDB

class PendingUserOperationRecord: Record {
    let userOpHash: String
    let deploymentId: String
    let implementationVersion: String
    let txHash: String?
    let status: String
    let submittedAt: TimeInterval
    let lastPolledAt: TimeInterval?
    let bundlerUrl: String

    init(
        userOpHash: String,
        deploymentId: String,
        implementationVersion: String,
        txHash: String?,
        status: String,
        submittedAt: TimeInterval,
        lastPolledAt: TimeInterval?,
        bundlerUrl: String
    ) {
        self.userOpHash = userOpHash
        self.deploymentId = deploymentId
        self.implementationVersion = implementationVersion
        self.txHash = txHash
        self.status = status
        self.submittedAt = submittedAt
        self.lastPolledAt = lastPolledAt
        self.bundlerUrl = bundlerUrl

        super.init()
    }

    override class var databaseTableName: String {
        "pending_user_operations"
    }

    enum Columns: String, ColumnExpression {
        case userOpHash, deploymentId, implementationVersion, txHash,
             status, submittedAt, lastPolledAt, bundlerUrl
    }

    required init(row: Row) throws {
        userOpHash = row[Columns.userOpHash]
        deploymentId = row[Columns.deploymentId]
        implementationVersion = row[Columns.implementationVersion]
        txHash = row[Columns.txHash]
        status = row[Columns.status]
        submittedAt = row[Columns.submittedAt]
        lastPolledAt = row[Columns.lastPolledAt]
        bundlerUrl = row[Columns.bundlerUrl]

        try super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.userOpHash] = userOpHash
        container[Columns.deploymentId] = deploymentId
        container[Columns.implementationVersion] = implementationVersion
        container[Columns.txHash] = txHash
        container[Columns.status] = status
        container[Columns.submittedAt] = submittedAt
        container[Columns.lastPolledAt] = lastPolledAt
        container[Columns.bundlerUrl] = bundlerUrl
    }
}

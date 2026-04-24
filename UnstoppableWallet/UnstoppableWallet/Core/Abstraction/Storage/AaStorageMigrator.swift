import Foundation
import GRDB

enum AaStorageMigrator {
    static func migrate(dbPool: DatabasePool) throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("Create SmartAccountProfile") { db in
            try db.create(table: SmartAccountProfileRecord.databaseTableName) { t in
                t.column(SmartAccountProfileRecord.Columns.id.name, .text).notNull().primaryKey()
                t.column(SmartAccountProfileRecord.Columns.accountId.name, .text).notNull().unique()
                t.column(SmartAccountProfileRecord.Columns.address.name, .text).notNull()
                t.column(SmartAccountProfileRecord.Columns.implementationVersion.name, .text).notNull()
                t.column(SmartAccountProfileRecord.Columns.verificationFacet.name, .text).notNull()
                t.column(SmartAccountProfileRecord.Columns.factoryAddress.name, .text).notNull()
                t.column(SmartAccountProfileRecord.Columns.entryPoint.name, .text).notNull()
                t.column(SmartAccountProfileRecord.Columns.ownerPublicKeyX.name, .text).notNull()
                t.column(SmartAccountProfileRecord.Columns.ownerPublicKeyY.name, .text).notNull()
                t.column(SmartAccountProfileRecord.Columns.salt.name, .text).notNull().defaults(to: "0")
                t.column(SmartAccountProfileRecord.Columns.createdAt.name, .double).notNull()
            }
        }

        migrator.registerMigration("Create SmartAccountDeployment") { db in
            try db.create(table: SmartAccountDeploymentRecord.databaseTableName) { t in
                t.column(SmartAccountDeploymentRecord.Columns.id.name, .text).notNull().primaryKey()
                t.column(SmartAccountDeploymentRecord.Columns.profileId.name, .text).notNull()
                    .references(SmartAccountProfileRecord.databaseTableName, onDelete: .cascade)
                t.column(SmartAccountDeploymentRecord.Columns.blockchainType.name, .text).notNull()
                t.column(SmartAccountDeploymentRecord.Columns.implementationVersion.name, .text).notNull()
                t.column(SmartAccountDeploymentRecord.Columns.isDeployed.name, .boolean).notNull().defaults(to: false)
                t.column(SmartAccountDeploymentRecord.Columns.preferredPaymaster.name, .text).notNull().defaults(to: "pimlico")
                t.column(SmartAccountDeploymentRecord.Columns.activatedAt.name, .double).notNull()
                t.uniqueKey([
                    SmartAccountDeploymentRecord.Columns.profileId.name,
                    SmartAccountDeploymentRecord.Columns.blockchainType.name,
                ])
            }
            try db.create(
                index: "idx_smart_account_deployments_profileId",
                on: SmartAccountDeploymentRecord.databaseTableName,
                columns: [SmartAccountDeploymentRecord.Columns.profileId.name]
            )
        }

        migrator.registerMigration("Create PendingUserOperation") { db in
            try db.create(table: PendingUserOperationRecord.databaseTableName) { t in
                t.column(PendingUserOperationRecord.Columns.userOpHash.name, .text).notNull().primaryKey()
                t.column(PendingUserOperationRecord.Columns.deploymentId.name, .text).notNull()
                    .references(SmartAccountDeploymentRecord.databaseTableName, onDelete: .cascade)
                t.column(PendingUserOperationRecord.Columns.implementationVersion.name, .text).notNull()
                t.column(PendingUserOperationRecord.Columns.txHash.name, .text)
                t.column(PendingUserOperationRecord.Columns.status.name, .text).notNull()
                t.column(PendingUserOperationRecord.Columns.submittedAt.name, .double).notNull()
                t.column(PendingUserOperationRecord.Columns.lastPolledAt.name, .double)
                t.column(PendingUserOperationRecord.Columns.bundlerUrl.name, .text).notNull()
            }
            try db.create(
                index: "idx_pending_user_operations_status",
                on: PendingUserOperationRecord.databaseTableName,
                columns: [PendingUserOperationRecord.Columns.status.name]
            )
        }

        try migrator.migrate(dbPool)
    }
}

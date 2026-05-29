import Foundation
import GRDB

enum AaStorageMigrator {
    static func migrate(dbPool: DatabasePool) throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("Create SmartAccountProfile") { db in
            try db.create(table: SmartAccountProfileRecord.databaseTableName) { t in
                t.column(SmartAccountProfileRecord.Columns.id.name, .text).notNull().primaryKey()
                t.column(SmartAccountProfileRecord.Columns.accountId.name, .text).notNull().unique()
                t.column(SmartAccountProfileRecord.Columns.implementationVersion.name, .text).notNull()
                t.column(SmartAccountProfileRecord.Columns.ownerPublicKeyX.name, .text).notNull()
                t.column(SmartAccountProfileRecord.Columns.ownerPublicKeyY.name, .text).notNull()
                t.column(SmartAccountProfileRecord.Columns.curve.name, .text).notNull()
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
            }
            try db.create(
                index: "idx_pending_user_operations_status",
                on: PendingUserOperationRecord.databaseTableName,
                columns: [PendingUserOperationRecord.Columns.status.name]
            )
        }

        migrator.registerMigration("Migrate SmartAccountProfile to AccountAbstractionProfile") { db in
            let legacyProfileTable = "smart_account_profiles"
            guard try db.tableExists(legacyProfileTable),
                  try db.tableExists(SmartAccountProfileRecord.databaseTableName) == false
            else {
                return
            }

            try db.create(table: SmartAccountProfileRecord.databaseTableName) { t in
                t.column(SmartAccountProfileRecord.Columns.id.name, .text).notNull().primaryKey()
                t.column(SmartAccountProfileRecord.Columns.accountId.name, .text).notNull().unique()
                t.column(SmartAccountProfileRecord.Columns.implementationVersion.name, .text).notNull()
                t.column(SmartAccountProfileRecord.Columns.ownerPublicKeyX.name, .text).notNull()
                t.column(SmartAccountProfileRecord.Columns.ownerPublicKeyY.name, .text).notNull()
                t.column(SmartAccountProfileRecord.Columns.curve.name, .text).notNull()
                t.column(SmartAccountProfileRecord.Columns.salt.name, .text).notNull().defaults(to: "0")
                t.column(SmartAccountProfileRecord.Columns.createdAt.name, .double).notNull()
            }

            try db.execute(sql: """
                INSERT INTO \(SmartAccountProfileRecord.databaseTableName)
                    (id, accountId, implementationVersion, ownerPublicKeyX, ownerPublicKeyY, curve, salt, createdAt)
                SELECT
                    id,
                    accountId,
                    implementationVersion,
                    ownerPublicKeyX,
                    ownerPublicKeyY,
                    CASE implementationVersion
                        WHEN 'barz_v1_ecdsa' THEN 'secp256k1'
                        ELSE 'secp256r1'
                    END,
                    salt,
                    createdAt
                FROM \(legacyProfileTable)
            """)

            let hasPendingUserOperations = try db.tableExists(PendingUserOperationRecord.databaseTableName)
            if hasPendingUserOperations {
                try db.execute(sql: "CREATE TEMP TABLE pending_user_operations_backup AS SELECT * FROM \(PendingUserOperationRecord.databaseTableName)")
                try db.drop(table: PendingUserOperationRecord.databaseTableName)
            }

            if try db.tableExists(SmartAccountDeploymentRecord.databaseTableName) {
                try db.execute(sql: "CREATE TEMP TABLE smart_account_deployments_backup AS SELECT * FROM \(SmartAccountDeploymentRecord.databaseTableName)")
                try db.drop(table: SmartAccountDeploymentRecord.databaseTableName)

                try createSmartAccountDeploymentTable(db)
                try db.execute(sql: """
                    INSERT INTO \(SmartAccountDeploymentRecord.databaseTableName)
                        (id, profileId, blockchainType, implementationVersion, isDeployed, preferredPaymaster, activatedAt)
                    SELECT id, profileId, blockchainType, implementationVersion, isDeployed, preferredPaymaster, activatedAt
                    FROM smart_account_deployments_backup
                """)
                try db.execute(sql: "DROP TABLE smart_account_deployments_backup")
            }

            if hasPendingUserOperations {
                try createPendingUserOperationTable(db)
                try db.execute(sql: """
                    INSERT INTO \(PendingUserOperationRecord.databaseTableName)
                        (userOpHash, deploymentId, implementationVersion, txHash, status, submittedAt, lastPolledAt)
                    SELECT userOpHash, deploymentId, implementationVersion, txHash, status, submittedAt, lastPolledAt
                    FROM pending_user_operations_backup
                """)
                try db.execute(sql: "DROP TABLE pending_user_operations_backup")
            }

            try db.drop(table: legacyProfileTable)
        }

        migrator.registerMigration("Create GasFreeProfile") { db in
            guard try db.tableExists(GasFreeProfileRecord.databaseTableName) == false else {
                return
            }

            try db.create(table: GasFreeProfileRecord.databaseTableName) { t in
                t.column(GasFreeProfileRecord.Columns.accountId.name, .text).notNull().primaryKey()
                t.column(GasFreeProfileRecord.Columns.controllerAddress.name, .text).notNull()
                t.column(GasFreeProfileRecord.Columns.gasFreeAddress.name, .text).notNull()
                t.column(GasFreeProfileRecord.Columns.providerId.name, .text).notNull()
                t.column(GasFreeProfileRecord.Columns.verifyingContract.name, .text).notNull()
                t.column(GasFreeProfileRecord.Columns.implementationVersion.name, .text).notNull()
                t.column(GasFreeProfileRecord.Columns.createdAt.name, .double).notNull()
                t.column(GasFreeProfileRecord.Columns.lastVerifiedAt.name, .double)
            }

            try db.create(table: PendingGasFreeTransferRecord.databaseTableName) { t in
                t.column(PendingGasFreeTransferRecord.Columns.traceId.name, .text).notNull().primaryKey()
                t.column(PendingGasFreeTransferRecord.Columns.accountId.name, .text).notNull()
                    .references(GasFreeProfileRecord.databaseTableName, onDelete: .cascade)
                t.column(PendingGasFreeTransferRecord.Columns.token.name, .text).notNull()
                t.column(PendingGasFreeTransferRecord.Columns.value.name, .text).notNull()
                t.column(PendingGasFreeTransferRecord.Columns.receiver.name, .text).notNull()
                t.column(PendingGasFreeTransferRecord.Columns.txnHash.name, .text)
                t.column(PendingGasFreeTransferRecord.Columns.status.name, .text).notNull()
                t.column(PendingGasFreeTransferRecord.Columns.submittedAt.name, .double).notNull()
                t.column(PendingGasFreeTransferRecord.Columns.lastPolledAt.name, .double)
            }
            try db.create(
                index: "idx_pending_gas_free_transfers_status",
                on: PendingGasFreeTransferRecord.databaseTableName,
                columns: [PendingGasFreeTransferRecord.Columns.status.name]
            )
        }

        try migrator.migrate(dbPool)
    }

    private static func createSmartAccountDeploymentTable(_ db: Database) throws {
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

    private static func createPendingUserOperationTable(_ db: Database) throws {
        try db.create(table: PendingUserOperationRecord.databaseTableName) { t in
            t.column(PendingUserOperationRecord.Columns.userOpHash.name, .text).notNull().primaryKey()
            t.column(PendingUserOperationRecord.Columns.deploymentId.name, .text).notNull()
                .references(SmartAccountDeploymentRecord.databaseTableName, onDelete: .cascade)
            t.column(PendingUserOperationRecord.Columns.implementationVersion.name, .text).notNull()
            t.column(PendingUserOperationRecord.Columns.txHash.name, .text)
            t.column(PendingUserOperationRecord.Columns.status.name, .text).notNull()
            t.column(PendingUserOperationRecord.Columns.submittedAt.name, .double).notNull()
            t.column(PendingUserOperationRecord.Columns.lastPolledAt.name, .double)
        }
        try db.create(
            index: "idx_pending_user_operations_status",
            on: PendingUserOperationRecord.databaseTableName,
            columns: [PendingUserOperationRecord.Columns.status.name]
        )
    }
}

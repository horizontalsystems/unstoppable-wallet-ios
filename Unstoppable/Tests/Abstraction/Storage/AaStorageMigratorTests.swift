import Foundation
import GRDB
import Testing
@testable import Unstoppable
@testable import WalletCore

struct AaStorageMigratorTests {
    @Test func createsAllTables() throws {
        let env = try AaStorageTestEnvironment()

        let hasProfile = try env.dbPool.read { db in
            try db.tableExists(SmartAccountProfileRecord.databaseTableName)
        }
        let hasDeployment = try env.dbPool.read { db in
            try db.tableExists(SmartAccountDeploymentRecord.databaseTableName)
        }
        let hasPending = try env.dbPool.read { db in
            try db.tableExists(PendingUserOperationRecord.databaseTableName)
        }
        let hasGasFree = try env.dbPool.read { db in
            try db.tableExists(GasFreeProfileRecord.databaseTableName)
        }
        #expect(hasProfile)
        #expect(hasDeployment)
        #expect(hasPending)
        #expect(hasGasFree)
    }

    @Test func migrationIsIdempotent() throws {
        let env = try AaStorageTestEnvironment()

        // Running the migrator twice on the same pool must not throw or drop data.
        let profile = env.makeProfile()
        try env.profileStorage.save(record: profile)

        try AaStorageMigrator.migrate(dbPool: env.dbPool)

        let restored = try env.profileStorage.profile(id: profile.id)
        #expect(restored != nil)
    }

    @Test func enforcesForeignKeys() throws {
        let env = try AaStorageTestEnvironment()

        // Saving a deployment whose profileId does not exist must fail — FK prevents orphans.
        let orphan = env.makeDeployment(profileId: "nonexistent-profile")

        #expect(throws: (any Error).self) {
            try env.dbPool.write { db in
                try orphan.insert(db)
            }
        }
    }

    @Test func migratesLegacySmartAccountProfilesAndPreservesChildren() throws {
        let dbURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("aa-legacy-migration-\(UUID().uuidString).sqlite")
        let dbPool = try DatabasePool(path: dbURL.path)

        try dbPool.write { db in
            try db.execute(sql: "CREATE TABLE grdb_migrations (identifier TEXT NOT NULL PRIMARY KEY)")
            try db.execute(sql: "INSERT INTO grdb_migrations (identifier) VALUES ('Create SmartAccountProfile'), ('Create SmartAccountDeployment'), ('Create PendingUserOperation')")

            try db.execute(sql: """
                CREATE TABLE smart_account_profiles (
                    id TEXT NOT NULL PRIMARY KEY,
                    accountId TEXT NOT NULL UNIQUE,
                    address TEXT NOT NULL,
                    implementationVersion TEXT NOT NULL,
                    ownerPublicKeyX TEXT NOT NULL,
                    ownerPublicKeyY TEXT NOT NULL,
                    salt TEXT NOT NULL DEFAULT '0',
                    createdAt DOUBLE NOT NULL
                )
            """)
            try db.execute(sql: """
                CREATE TABLE smart_account_deployments (
                    id TEXT NOT NULL PRIMARY KEY,
                    profileId TEXT NOT NULL REFERENCES smart_account_profiles(id) ON DELETE CASCADE,
                    blockchainType TEXT NOT NULL,
                    implementationVersion TEXT NOT NULL,
                    isDeployed BOOLEAN NOT NULL DEFAULT 0,
                    preferredPaymaster TEXT NOT NULL DEFAULT 'pimlico',
                    activatedAt DOUBLE NOT NULL,
                    UNIQUE (profileId, blockchainType)
                )
            """)
            try db.execute(sql: """
                CREATE TABLE pending_user_operations (
                    userOpHash TEXT NOT NULL PRIMARY KEY,
                    deploymentId TEXT NOT NULL REFERENCES smart_account_deployments(id) ON DELETE CASCADE,
                    implementationVersion TEXT NOT NULL,
                    txHash TEXT,
                    status TEXT NOT NULL,
                    submittedAt DOUBLE NOT NULL,
                    lastPolledAt DOUBLE
                )
            """)

            try db.execute(sql: """
                INSERT INTO smart_account_profiles
                    (id, accountId, address, implementationVersion, ownerPublicKeyX, ownerPublicKeyY, salt, createdAt)
                VALUES
                    ('profile-1', 'account-1', '0x1111111111111111111111111111111111111111', 'barz_v1_ecdsa', '\(String(repeating: "11", count: 32))', '\(String(repeating: "22", count: 32))', '0', 1700000000)
            """)
            try db.execute(sql: """
                INSERT INTO smart_account_deployments
                    (id, profileId, blockchainType, implementationVersion, isDeployed, preferredPaymaster, activatedAt)
                VALUES
                    ('deployment-1', 'profile-1', 'binance-smart-chain', 'barz_v1_ecdsa', 1, 'pimlico', 1700000001)
            """)
            try db.execute(sql: """
                INSERT INTO pending_user_operations
                    (userOpHash, deploymentId, implementationVersion, txHash, status, submittedAt, lastPolledAt)
                VALUES
                    ('0xabc', 'deployment-1', 'barz_v1_ecdsa', '0xdef', 'submitted', 1700000002, 1700000003)
            """)
        }

        try AaStorageMigrator.migrate(dbPool: dbPool)

        let result = try dbPool.read { db in
            try (
                legacyExists: db.tableExists("smart_account_profiles"),
                profile: SmartAccountProfileRecord.fetchOne(db),
                deployment: SmartAccountDeploymentRecord.fetchOne(db),
                pending: PendingUserOperationRecord.fetchOne(db),
                gasFreeExists: db.tableExists(GasFreeProfileRecord.databaseTableName)
            )
        }

        #expect(result.legacyExists == false)
        #expect(result.profile?.id == "profile-1")
        #expect(result.profile?.accountId == "account-1")
        #expect(result.profile?.curve == "secp256k1")
        #expect(result.deployment?.id == "deployment-1")
        #expect(result.deployment?.profileId == "profile-1")
        #expect(result.deployment?.isDeployed == true)
        #expect(result.pending?.userOpHash == "0xabc")
        #expect(result.pending?.deploymentId == "deployment-1")
        #expect(result.pending?.txHash == "0xdef")
        #expect(result.gasFreeExists)
    }
}

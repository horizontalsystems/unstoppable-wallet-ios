import Foundation
import GRDB
import Testing
@testable import Unstoppable

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
        #expect(hasProfile)
        #expect(hasDeployment)
        #expect(hasPending)
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
}

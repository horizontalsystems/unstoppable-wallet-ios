import GRDB

class SmartAccountDeploymentRecordStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }
}

extension SmartAccountDeploymentRecordStorage {
    func all() throws -> [SmartAccountDeploymentRecord] {
        try dbPool.read { db in
            try SmartAccountDeploymentRecord.fetchAll(db)
        }
    }

    func deployments(profileId: String) throws -> [SmartAccountDeploymentRecord] {
        try dbPool.read { db in
            try SmartAccountDeploymentRecord
                .filter(SmartAccountDeploymentRecord.Columns.profileId == profileId)
                .fetchAll(db)
        }
    }

    func deployment(profileId: String, blockchainType: String) throws -> SmartAccountDeploymentRecord? {
        try dbPool.read { db in
            try SmartAccountDeploymentRecord
                .filter(SmartAccountDeploymentRecord.Columns.profileId == profileId)
                .filter(SmartAccountDeploymentRecord.Columns.blockchainType == blockchainType)
                .fetchOne(db)
        }
    }

    func save(record: SmartAccountDeploymentRecord) throws {
        try dbPool.write { db in
            try record.insert(db)
        }
    }

    func updateDeployed(id: String, isDeployed: Bool) throws {
        try dbPool.write { db in
            try SmartAccountDeploymentRecord
                .filter(SmartAccountDeploymentRecord.Columns.id == id)
                .updateAll(db, SmartAccountDeploymentRecord.Columns.isDeployed.set(to: isDeployed))
        }
    }

    func delete(id: String) throws {
        try dbPool.write { db in
            try SmartAccountDeploymentRecord
                .filter(SmartAccountDeploymentRecord.Columns.id == id)
                .deleteAll(db)
        }
    }

    func deleteAll(profileId: String) throws {
        try dbPool.write { db in
            try SmartAccountDeploymentRecord
                .filter(SmartAccountDeploymentRecord.Columns.profileId == profileId)
                .deleteAll(db)
        }
    }

    func clear() throws {
        try dbPool.write { db in
            try SmartAccountDeploymentRecord.deleteAll(db)
        }
    }
}

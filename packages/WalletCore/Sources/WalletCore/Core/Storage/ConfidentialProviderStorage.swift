import Foundation
import GRDB

public class ConfidentialProviderStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }
}

public extension ConfidentialProviderStorage {
    func providerIds() throws -> [String] {
        try dbPool.read { db in
            try ConfidentialProviderRecord.fetchAll(db).map(\.providerId)
        }
    }

    func executionTypes() throws -> [String: String] {
        try dbPool.read { db in
            try Dictionary(
                uniqueKeysWithValues: ConfidentialProviderRecord.fetchAll(db).map { ($0.providerId, $0.executionType) }
            )
        }
    }

    func lastSyncTimestamp() throws -> TimeInterval? {
        try dbPool.read { db in
            try ConfidentialProviderRecord.fetchAll(db).map(\.lastSyncTimestamp).min()
        }
    }

    // Whole-list replace: a provider the server stops marking confidential must disappear, so a
    // partial upsert would be wrong.
    func save(providerIds: [String], executionTypes: [String: String], lastSyncTimestamp: TimeInterval) throws {
        _ = try dbPool.write { db in
            try ConfidentialProviderRecord.deleteAll(db)

            for providerId in providerIds {
                let record = ConfidentialProviderRecord(
                    providerId: providerId,
                    executionType: executionTypes[providerId] ?? "",
                    lastSyncTimestamp: lastSyncTimestamp
                )
                try record.insert(db)
            }
        }
    }
}

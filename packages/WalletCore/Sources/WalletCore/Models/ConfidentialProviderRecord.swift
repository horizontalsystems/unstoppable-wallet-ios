import Foundation
import GRDB

class ConfidentialProviderRecord: Codable {
    let providerId: String
    let executionType: String
    let lastSyncTimestamp: TimeInterval

    init(providerId: String, executionType: String, lastSyncTimestamp: TimeInterval) {
        self.providerId = providerId
        self.executionType = executionType
        self.lastSyncTimestamp = lastSyncTimestamp
    }
}

extension ConfidentialProviderRecord: FetchableRecord, PersistableRecord {
    class var databaseTableName: String {
        "ConfidentialProviderRecord"
    }

    enum Columns {
        static let providerId = Column(CodingKeys.providerId)
        static let executionType = Column(CodingKeys.executionType)
        static let lastSyncTimestamp = Column(CodingKeys.lastSyncTimestamp)
    }
}

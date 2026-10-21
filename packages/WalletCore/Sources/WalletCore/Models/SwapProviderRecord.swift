import Foundation
import GRDB

/// One `GET /v3/providers` entry as the swap screen caches it between syncs. The table is replaced
/// whole on every sync, so a provider the server stops listing disappears with it.
class SwapProviderRecord: Codable {
    let providerId: String
    /// The server's order, which the provider list keeps.
    let position: Int
    /// How the provider settles (`thorchain_deposit`, `signed_transaction`, ...).
    let executionType: String?
    /// `excellent` | `good` | `fair`, as published; mapped to `SwapProviderType` when restored.
    let amlPolicy: String?
    /// Whether the provider serves the `/v3/split/*` endpoints, i.e. can be quoted on the Private swap tab.
    let split: Bool
    /// The provider's scoped suspensions as a JSON array of rules, nil when it has none.
    let suspensions: String?
    let lastSyncTimestamp: TimeInterval

    init(providerId: String, position: Int, executionType: String?, amlPolicy: String?, split: Bool, suspensions: String?, lastSyncTimestamp: TimeInterval) {
        self.providerId = providerId
        self.position = position
        self.executionType = executionType
        self.amlPolicy = amlPolicy
        self.split = split
        self.suspensions = suspensions
        self.lastSyncTimestamp = lastSyncTimestamp
    }
}

extension SwapProviderRecord: FetchableRecord, PersistableRecord {
    class var databaseTableName: String {
        "SwapProviderRecord"
    }

    enum Columns {
        static let providerId = Column(CodingKeys.providerId)
        static let position = Column(CodingKeys.position)
        static let executionType = Column(CodingKeys.executionType)
        static let amlPolicy = Column(CodingKeys.amlPolicy)
        static let split = Column(CodingKeys.split)
        static let suspensions = Column(CodingKeys.suspensions)
        static let lastSyncTimestamp = Column(CodingKeys.lastSyncTimestamp)
    }
}

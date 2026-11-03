import Foundation
import GRDB

/// One `GET /v3/providers` entry as the swap screen caches it between syncs. The table is replaced
/// whole on every sync, so a provider the server stops listing disappears with it.
class SwapProviderRecord: Codable {
    let providerId: String
    /// The server's order, which the provider list keeps.
    let position: Int
    /// Display name as published (the humanized id when the server sends none).
    let name: String
    /// How the provider settles (`thorchain_deposit`, `signed_transaction`, `transfer`, ...).
    let executionType: String?
    /// `excellent` | `good` | `fair`, as published; mapped to `SwapProviderType` when read.
    let amlPolicy: String?
    /// `none` | `basic` | ...; any value other than `none` is confidential.
    let privacy: String
    /// Whether the provider serves the `/v3/split/*` endpoints, i.e. can be quoted on the Private swap tab.
    let splitSwaps: Bool
    let lastSyncTimestamp: TimeInterval

    init(providerId: String, position: Int, name: String, executionType: String?, amlPolicy: String?, privacy: String, splitSwaps: Bool, lastSyncTimestamp: TimeInterval) {
        self.providerId = providerId
        self.position = position
        self.name = name
        self.executionType = executionType
        self.amlPolicy = amlPolicy
        self.privacy = privacy
        self.splitSwaps = splitSwaps
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
        static let name = Column(CodingKeys.name)
        static let executionType = Column(CodingKeys.executionType)
        static let amlPolicy = Column(CodingKeys.amlPolicy)
        static let privacy = Column(CodingKeys.privacy)
        static let splitSwaps = Column(CodingKeys.splitSwaps)
        static let lastSyncTimestamp = Column(CodingKeys.lastSyncTimestamp)
    }
}

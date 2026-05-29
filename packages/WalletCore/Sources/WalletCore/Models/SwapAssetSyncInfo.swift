import Foundation
import GRDB

class SwapAssetSyncInfo: Codable {
    let provider: String
    let lastSyncTimestamp: TimeInterval

    init(provider: String, lastSyncTimestamp: TimeInterval) {
        self.provider = provider
        self.lastSyncTimestamp = lastSyncTimestamp
    }
}

extension SwapAssetSyncInfo: FetchableRecord, PersistableRecord {
    class var databaseTableName: String {
        "SwapAssetSyncInfo"
    }

    enum Columns {
        static let provider = Column(CodingKeys.provider)
        static let lastSyncTimestamp = Column(CodingKeys.lastSyncTimestamp)
    }
}

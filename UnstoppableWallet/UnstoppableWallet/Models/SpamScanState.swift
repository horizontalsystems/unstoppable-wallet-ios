import Foundation
import GRDB

struct SpamScanState: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "spamScanStates"

    let blockchainTypeUid: String
    let accountUid: String
    let lastPaginationData: String

    enum Columns: String, ColumnExpression {
        case blockchainTypeUid
        case accountUid
        case lastPaginationData
    }
}

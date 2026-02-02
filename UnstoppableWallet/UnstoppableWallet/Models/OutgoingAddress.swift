import Foundation
import GRDB

struct OutgoingAddress: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "outgoing_addresses"

    let address: String
    let blockchainTypeUid: String
    let accountUid: String
    let timestamp: Int
    let blockHeight: Int?

    enum Columns: String, ColumnExpression {
        case address
        case blockchainTypeUid
        case accountUid
        case timestamp
        case blockHeight
    }
}

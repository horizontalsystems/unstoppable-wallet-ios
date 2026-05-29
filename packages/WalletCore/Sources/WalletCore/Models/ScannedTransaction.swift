import Foundation
import GRDB

struct ScannedTransaction: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "scannedTransactions"

    let transactionHash: Data
    let blockchainTypeUid: String
    let isSpam: Bool
    let spamAddress: String?

    enum Columns: String, ColumnExpression {
        case transactionHash
        case blockchainTypeUid
        case isSpam
        case spamAddress
    }
}

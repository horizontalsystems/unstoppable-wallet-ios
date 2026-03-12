import Foundation
import GRDB
import MarketKit

struct Swap: Hashable {
    let txHash: String
    let accountId: String
    let providerId: String
    var status: Status
    let tokenIn: Token
    let tokenOut: Token
    let amountIn: Decimal
    var amountOut: Decimal
    let toAddress: String
    let depositAddress: String?
    let providerSwapId: String?
    let date: Date

    static var pendingStatuses: [Status] {
        [.notStarted, .pending, .swapping, .unknown]
    }

    enum Status: String {
        case notStarted = "not_started"
        case pending
        case swapping
        case completed
        case refunded
        case unknown
        case failed
    }
}

struct SwapRecord: Codable {
    let txHash: String
    let accountId: String
    let providerId: String
    let status: String
    let tokenQueryIdIn: String
    let tokenQueryIdOut: String
    let amountIn: String
    let amountOut: String
    let toAddress: String
    let depositAddress: String?
    let providerSwapId: String?
    let date: Date
}

extension SwapRecord: FetchableRecord, PersistableRecord {
    static var databaseTableName: String {
        "SwapRecord"
    }

    enum Columns {
        static let txHash = Column(CodingKeys.txHash)
        static let accountId = Column(CodingKeys.accountId)
        static let providerId = Column(CodingKeys.providerId)
        static let status = Column(CodingKeys.status)
        static let tokenQueryIdIn = Column(CodingKeys.tokenQueryIdIn)
        static let tokenQueryIdOut = Column(CodingKeys.tokenQueryIdOut)
        static let amountIn = Column(CodingKeys.amountIn)
        static let amountOut = Column(CodingKeys.amountOut)
        static let toAddress = Column(CodingKeys.toAddress)
        static let depositAddress = Column(CodingKeys.depositAddress)
        static let providerSwapId = Column(CodingKeys.providerSwapId)
        static let date = Column(CodingKeys.date)
    }
}

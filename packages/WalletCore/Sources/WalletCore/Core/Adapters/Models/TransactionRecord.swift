import Foundation
import MarketKit

open class TransactionRecord {
    public let source: TransactionSource
    public let uid: String
    public let transactionHash: String
    public let transactionIndex: Int
    public let blockHeight: Int?
    public let confirmationsThreshold: Int?
    public let date: Date
    public let failed: Bool

    public var spam: Bool
    public var paginationRaw: String

    public init(source: TransactionSource, uid: String, transactionHash: String, transactionIndex: Int, blockHeight: Int?, confirmationsThreshold: Int?, date: Date, failed: Bool, paginationRaw: String? = nil, spam: Bool = false) {
        self.source = source
        self.uid = uid
        self.transactionHash = transactionHash
        self.transactionIndex = transactionIndex
        self.blockHeight = blockHeight
        self.confirmationsThreshold = confirmationsThreshold
        self.date = date
        self.failed = failed
        self.spam = spam

        self.paginationRaw = paginationRaw ?? transactionHash
    }

    open func status(lastBlockHeight: Int?) -> TransactionStatus {
        if failed {
            return .failed
        } else if let blockHeight, let lastBlockHeight {
            let threshold = confirmationsThreshold ?? 1
            let confirmations = lastBlockHeight - blockHeight + 1

            if confirmations >= threshold {
                return .completed
            } else {
                return .processing(progress: Double(max(0, confirmations)) / Double(threshold))
            }
        }

        return .pending
    }

    open func lockState(lastBlockTimestamp _: Int?) -> TransactionLockState? {
        nil
    }

    open var mainToken: MarketKit.Token? {
        nil
    }

    open var mainValue: Decimal? {
        nil
    }
}

extension TransactionRecord: Identifiable {
    public var id: String {
        uid
    }
}

extension TransactionRecord: Comparable {
    public static func < (lhs: TransactionRecord, rhs: TransactionRecord) -> Bool {
        guard lhs.date == rhs.date else {
            return lhs.date > rhs.date
        }

        guard lhs.transactionIndex == rhs.transactionIndex else {
            return lhs.transactionIndex > rhs.transactionIndex
        }

        return lhs.paginationRaw > rhs.paginationRaw
    }

    public static func == (lhs: TransactionRecord, rhs: TransactionRecord) -> Bool {
        lhs.uid == rhs.uid
    }
}

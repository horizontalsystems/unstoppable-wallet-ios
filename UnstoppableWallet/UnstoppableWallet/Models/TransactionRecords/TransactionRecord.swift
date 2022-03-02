import Foundation

class TransactionRecord {
    let source: TransactionSource
    let uid: String
    let transactionHash: String
    let transactionIndex: Int
    let blockHeight: Int?
    let confirmationsThreshold: Int?
    let date: Date
    let failed: Bool

    init(source: TransactionSource, uid: String, transactionHash: String, transactionIndex: Int, blockHeight: Int?, confirmationsThreshold: Int?, date: Date, failed: Bool) {
        self.source = source
        self.uid = uid
        self.transactionHash = transactionHash
        self.transactionIndex = transactionIndex
        self.blockHeight = blockHeight
        self.confirmationsThreshold = confirmationsThreshold
        self.date = date
        self.failed = failed
    }

    func status(lastBlockHeight: Int?) -> TransactionStatus {
        if failed {
            return .failed
        } else if let blockHeight = blockHeight, let lastBlockHeight = lastBlockHeight {
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

    open var mainValue: TransactionValue? {
        nil
    }

    open func changedBy(oldBlockInfo: LastBlockInfo?, newBlockInfo: LastBlockInfo?) -> Bool {
        status(lastBlockHeight: oldBlockInfo?.height) != status(lastBlockHeight: newBlockInfo?.height)
    }

}

extension TransactionRecord: Comparable {

    public static func <(lhs: TransactionRecord, rhs: TransactionRecord) -> Bool {
        guard lhs.date == rhs.date else {
            return lhs.date < rhs.date
        }

        guard lhs.transactionIndex == rhs.transactionIndex else {
            return lhs.transactionIndex < rhs.transactionIndex
        }

        return lhs.uid < rhs.uid
    }

    public static func ==(lhs: TransactionRecord, rhs: TransactionRecord) -> Bool {
        lhs.uid == rhs.uid
    }

}

enum TransactionStatus {
    case failed
    case pending
    case processing(progress: Double)
    case completed
}

extension TransactionStatus: Equatable {

    public static func ==(lhs: TransactionStatus, rhs: TransactionStatus) -> Bool {
        switch (lhs, rhs) {
        case (.failed, .failed): return true
        case (.pending, .pending): return true
        case (let .processing(lhsProgress), let .processing(rhsProgress)): return lhsProgress == rhsProgress
        case (.completed, .completed): return true
        default: return false
        }
    }

}

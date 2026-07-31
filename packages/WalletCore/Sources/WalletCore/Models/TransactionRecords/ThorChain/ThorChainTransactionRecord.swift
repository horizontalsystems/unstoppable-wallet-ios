import Foundation
import MarketKit
import ThorChainKit

class ThorChainTransactionRecord: TransactionRecord {
    let transaction: ThorChainKit.Transaction

    // One Midgard action can produce several records — one per user-side asset — so the
    // hash alone is not a unique identity and callers pass an asset-qualified uid.
    init(source: TransactionSource, transaction: ThorChainKit.Transaction, uid: String? = nil) {
        self.transaction = transaction

        super.init(
            source: source,
            uid: uid ?? transaction.transactionId.hash,
            transactionHash: transaction.transactionId.hash,
            transactionIndex: 0,
            blockHeight: transaction.isPending ? nil : Int(exactly: transaction.blockHeight),
            confirmationsThreshold: nil,
            date: transaction.timestamp,
            failed: transaction.status.caseInsensitiveCompare("failed") == .orderedSame,
            paginationRaw: transaction.transactionId.hash
        )
    }

    override func status(lastBlockHeight _: Int?) -> TransactionStatus {
        switch transaction.status.lowercased() {
        case "success", "refund": return .completed
        case "failed": return .failed
        default: return .pending
        }
    }
}

class ThorChainIncomingTransactionRecord: ThorChainTransactionRecord, TransferEventsProvider {
    let from: String?
    let value: AppValue

    init(source: TransactionSource, transaction: ThorChainKit.Transaction, uid: String, from: String?, value: AppValue) {
        self.from = from
        self.value = value

        super.init(source: source, transaction: transaction, uid: uid)
    }

    override var mainValue: AppValue? {
        value
    }

    var transferEvents: TransferEvents {
        .init(incoming: [.init(address: from ?? "", value: value)])
    }
}

class ThorChainOutgoingTransactionRecord: ThorChainTransactionRecord {
    let to: String?
    let value: AppValue
    let sentToSelf: Bool

    init(source: TransactionSource, transaction: ThorChainKit.Transaction, uid: String, to: String?, value: AppValue, sentToSelf: Bool) {
        self.to = to
        self.value = value
        self.sentToSelf = sentToSelf

        super.init(source: source, transaction: transaction, uid: uid)
    }

    override var mainValue: AppValue? {
        value
    }
}

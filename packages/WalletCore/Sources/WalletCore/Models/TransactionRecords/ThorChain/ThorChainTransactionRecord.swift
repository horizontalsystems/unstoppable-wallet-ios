import Foundation
import MarketKit
import ThorChainKit

class ThorChainTransactionRecord: TransactionRecord {
    let transaction: ThorChainKit.Transaction
    let fee: AppValue?

    // One Midgard action can produce several records — one per user-side asset — so the
    // hash alone is not a unique identity and callers pass an asset-qualified uid.
    init(source: TransactionSource, transaction: ThorChainKit.Transaction, baseToken: Token, uid: String? = nil) {
        self.transaction = transaction

        if let feeAmount = transaction.fee {
            let feeDecimal = Decimal(sign: .plus, exponent: -baseToken.decimals, significand: Decimal(string: String(feeAmount)) ?? 0)
            fee = AppValue(token: baseToken, value: feeDecimal)
        } else {
            fee = nil
        }

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

    init(source: TransactionSource, transaction: ThorChainKit.Transaction, baseToken: Token, uid: String, from: String?, value: AppValue) {
        self.from = from
        self.value = value

        super.init(source: source, transaction: transaction, baseToken: baseToken, uid: uid)
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

    init(source: TransactionSource, transaction: ThorChainKit.Transaction, baseToken: Token, uid: String, to: String?, value: AppValue, sentToSelf: Bool) {
        self.to = to
        self.value = value
        self.sentToSelf = sentToSelf

        super.init(source: source, transaction: transaction, baseToken: baseToken, uid: uid)
    }

    override var mainValue: AppValue? {
        value
    }
}

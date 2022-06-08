import Foundation
import MarketKit

class BitcoinIncomingTransactionRecord: BitcoinTransactionRecord {
    let value: TransactionValue
    let from: String?

    init(token: Token, source: TransactionSource, uid: String, transactionHash: String, transactionIndex: Int, blockHeight: Int?, confirmationsThreshold: Int?, date: Date, fee: Decimal?, failed: Bool,
         lockInfo: TransactionLockInfo?, conflictingHash: String?, showRawTransaction: Bool,
         amount: Decimal, from: String?, memo: String? = nil) {
        value = .coinValue(token: token, value: amount)
        self.from = from

        super.init(
                source: source,
                uid: uid,
                transactionHash: transactionHash,
                transactionIndex: transactionIndex,
                blockHeight: blockHeight,
                confirmationsThreshold: confirmationsThreshold,
                date: date,
                fee: fee.flatMap { .coinValue(token: token, value: $0) },
                failed: failed,
                lockInfo: lockInfo,
                conflictingHash: conflictingHash,
                showRawTransaction: showRawTransaction,
                memo: memo
        )
    }

    override var mainValue: TransactionValue? {
        value
    }

}

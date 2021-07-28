import Foundation
import CoinKit

class BitcoinOutgoingTransactionRecord: BitcoinTransactionRecord {
    let value: CoinValue
    let to: String?
    let sentToSelf: Bool

    init(coin: Coin, uid: String, transactionHash: String, transactionIndex: Int, blockHeight: Int?, confirmationsThreshold: Int?, date: Date, fee: Decimal?, failed: Bool,
         lockInfo: TransactionLockInfo?, conflictingHash: String?, showRawTransaction: Bool,
         amount: Decimal, to: String?, sentToSelf: Bool, memo: String? = nil) {
        value = CoinValue(coin: coin, value: amount)
        self.to = to
        self.sentToSelf = sentToSelf

        super.init(
                uid: uid,
                transactionHash: transactionHash,
                transactionIndex: transactionIndex,
                blockHeight: blockHeight,
                confirmationsThreshold: confirmationsThreshold,
                date: date,
                fee: fee.flatMap { CoinValue(coin: coin, value: $0) },
                failed: failed,
                lockInfo: lockInfo,
                conflictingHash: conflictingHash,
                showRawTransaction: showRawTransaction,
                memo: memo
        )
    }

    override var mainValue: CoinValue? {
        value
    }

}

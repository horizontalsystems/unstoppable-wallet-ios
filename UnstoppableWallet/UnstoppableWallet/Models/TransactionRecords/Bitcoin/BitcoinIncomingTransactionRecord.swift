import Foundation
import CoinKit

class BitcoinIncomingTransactionRecord: BitcoinTransactionRecord {
    let value: CoinValue
    let from: String?

    init(coin: Coin, uid: String, transactionHash: String, transactionIndex: Int, blockHeight: Int?, confirmationsThreshold: Int?, date: Date, fee: Decimal?, failed: Bool,
         lockInfo: TransactionLockInfo?, conflictingHash: String?, showRawTransaction: Bool,
         amount: Decimal, from: String?, memo: String? = nil) {
        value = CoinValue(coin: coin, value: amount)
        self.from = from

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

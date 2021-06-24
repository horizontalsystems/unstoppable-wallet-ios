import Foundation
import CoinKit

class BitcoinIncomingTransactionRecord: BitcoinTransactionRecord {
    let amount: Decimal
    let from: String?

    init(coin: Coin, uid: String, transactionHash: String, transactionIndex: Int, blockHeight: Int?, confirmationsThreshold: Int?, date: Date, fee: Decimal?, failed: Bool,
         lockInfo: TransactionLockInfo?, conflictingHash: String?, showRawTransaction: Bool,
         amount: Decimal, from: String?) {
        self.amount = amount
        self.from = from

        super.init(
                coin: coin,
                uid: uid,
                transactionHash: transactionHash,
                transactionIndex: transactionIndex,
                blockHeight: blockHeight,
                confirmationsThreshold: confirmationsThreshold,
                date: date,
                fee: fee,
                failed: failed,
                lockInfo: lockInfo,
                conflictingHash: conflictingHash,
                showRawTransaction: showRawTransaction
        )
    }

    override var mainAmount: Decimal? {
        amount
    }

    override func type(lastBlockInfo: LastBlockInfo?) -> TransactionType {
        let coinValue: CoinValue = CoinValue(coin: coin, value: amount)
        let lState = lockState(lastBlockTimestamp: lastBlockInfo?.timestamp)

        return .incoming(from: from, coinValue: coinValue, lockState: lState, conflictingTxHash: conflictingHash)
    }

}

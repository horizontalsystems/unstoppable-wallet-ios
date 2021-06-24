import Foundation
import CoinKit

class BitcoinOutgoingTransactionRecord: BitcoinTransactionRecord {
    let amount: Decimal
    let to: String?
    let sentToSelf: Bool

    init(coin: Coin, uid: String, transactionHash: String, transactionIndex: Int, blockHeight: Int?, confirmationsThreshold: Int?, date: Date, fee: Decimal?, failed: Bool,
         lockInfo: TransactionLockInfo?, conflictingHash: String?, showRawTransaction: Bool,
         amount: Decimal, to: String?, sentToSelf: Bool) {
        self.amount = amount
        self.to = to
        self.sentToSelf = sentToSelf

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
        return .outgoing(to: to, coinValue: coinValue, lockState: lState, conflictingTxHash: conflictingHash, sentToSelf: sentToSelf)
    }

}

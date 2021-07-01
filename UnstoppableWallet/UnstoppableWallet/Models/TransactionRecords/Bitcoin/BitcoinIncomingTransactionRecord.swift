import Foundation
import CoinKit

class BitcoinIncomingTransactionRecord: BitcoinTransactionRecord {
    let value: CoinValue
    let from: String?

    init(coin: Coin, uid: String, transactionHash: String, transactionIndex: Int, blockHeight: Int?, confirmationsThreshold: Int?, date: Date, fee: Decimal?, failed: Bool,
         lockInfo: TransactionLockInfo?, conflictingHash: String?, showRawTransaction: Bool,
         amount: Decimal, from: String?) {
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
                showRawTransaction: showRawTransaction
        )
    }

    override var mainValue: CoinValue? {
        value
    }

    override func type(lastBlockInfo: LastBlockInfo?) -> TransactionType {
        let lState = lockState(lastBlockTimestamp: lastBlockInfo?.timestamp)

        return .incoming(from: from, coinValue: value, lockState: lState, conflictingTxHash: conflictingHash)
    }

}

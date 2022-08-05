import Foundation
import MarketKit

class BitcoinTransactionRecord: TransactionRecord {
    let lockInfo: TransactionLockInfo?
    let fee: TransactionValue?
    let conflictingHash: String?
    let showRawTransaction: Bool
    let memo: String?

    init(source: TransactionSource, uid: String, transactionHash: String, transactionIndex: Int, blockHeight: Int?, confirmationsThreshold: Int?, date: Date, fee: TransactionValue?, failed: Bool,
         lockInfo: TransactionLockInfo?, conflictingHash: String?, showRawTransaction: Bool, memo: String?) {
        self.lockInfo = lockInfo
        self.fee = fee
        self.conflictingHash = conflictingHash
        self.showRawTransaction = showRawTransaction
        self.memo = memo

        super.init(
                source: source,
                uid: uid,
                transactionHash: transactionHash,
                transactionIndex: transactionIndex,
                blockHeight: blockHeight,
                confirmationsThreshold: confirmationsThreshold,
                date: date,
                failed: failed
        )
    }

    override func lockState(lastBlockTimestamp: Int?) -> TransactionLockState? {
        guard let lockInfo = lockInfo else {
            return nil
        }

        var locked = true

        if let lastBlockTimestamp = lastBlockTimestamp {
            locked = Double(lastBlockTimestamp) < lockInfo.lockedUntil.timeIntervalSince1970
        }

        return TransactionLockState(locked: locked, date: lockInfo.lockedUntil)
    }

}

struct TransactionLockState {
    let locked: Bool
    let date: Date
}

extension TransactionLockState: Equatable {

    public static func ==(lhs: TransactionLockState, rhs: TransactionLockState) -> Bool {
        lhs.locked == rhs.locked && lhs.date == rhs.date
    }

}

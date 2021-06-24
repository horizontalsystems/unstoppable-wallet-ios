import Foundation
import CoinKit

class BitcoinTransactionRecord: TransactionRecord {
    let coin: Coin
    let lockInfo: TransactionLockInfo?
    let conflictingHash: String?
    let showRawTransaction: Bool

    init(coin: Coin, uid: String, transactionHash: String, transactionIndex: Int, blockHeight: Int?, confirmationsThreshold: Int?, date: Date, fee: Decimal?, failed: Bool,
         lockInfo: TransactionLockInfo?, conflictingHash: String?, showRawTransaction: Bool) {
        self.coin = coin
        self.lockInfo = lockInfo
        self.conflictingHash = conflictingHash
        self.showRawTransaction = showRawTransaction

        super.init(
                uid: uid,
                transactionHash: transactionHash,
                transactionIndex: transactionIndex,
                blockHeight: blockHeight,
                confirmationsThreshold: confirmationsThreshold,
                date: date,
                fee: fee,
                failed: failed
        )
    }

    private func becomesUnlocked(oldTimestamp: Int?, newTimestamp: Int?) -> Bool {
        guard let lockTime = lockInfo?.lockedUntil.timeIntervalSince1970, let newTimestamp = newTimestamp else {
            return false
        }

        return lockTime > Double(oldTimestamp ?? 0) && // was locked
                lockTime <= Double(newTimestamp)       // now unlocked
    }

    func lockState(lastBlockTimestamp: Int?) -> TransactionLockState? {
        guard let lockInfo = lockInfo else {
            return nil
        }

        var locked = true

        if let lastBlockTimestamp = lastBlockTimestamp {
            locked = Double(lastBlockTimestamp) < lockInfo.lockedUntil.timeIntervalSince1970
        }

        return TransactionLockState(locked: locked, date: lockInfo.lockedUntil)
    }

    override var mainCoin: Coin? {
        coin
    }

    override func changedBy(oldBlockInfo: LastBlockInfo?, newBlockInfo: LastBlockInfo?) -> Bool {
        super.changedBy(oldBlockInfo: oldBlockInfo, newBlockInfo: newBlockInfo) ||
                becomesUnlocked(oldTimestamp: oldBlockInfo?.timestamp, newTimestamp: newBlockInfo?.timestamp)
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

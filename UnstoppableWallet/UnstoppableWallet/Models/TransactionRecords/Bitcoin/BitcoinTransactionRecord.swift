import Foundation
import MarketKit

class BitcoinTransactionRecord: TransactionRecord {
    let lockInfo: TransactionLockInfo?
    let fee: AppValue?
    let conflictingHash: String?
    let showRawTransaction: Bool
    let memo: String?

    init(source: TransactionSource, uid: String, transactionHash: String, transactionIndex: Int, blockHeight: Int?, confirmationsThreshold: Int?, date: Date, fee: AppValue?, failed: Bool,
         lockInfo: TransactionLockInfo?, conflictingHash: String?, showRawTransaction: Bool, memo: String?)
    {
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
        guard let lockInfo else {
            return nil
        }

        var locked = true

        if let lastBlockTimestamp {
            locked = Double(lastBlockTimestamp) < lockInfo.lockedUntil.timeIntervalSince1970
        }

        return TransactionLockState(locked: locked, date: lockInfo.lockedUntil)
    }

    override var rateTokens: [Token?] {
        super.rateTokens + [fee?.token]
    }

    func fields(lastBlockInfo: LastBlockInfo?) -> [TransactionField] {
        var fields = [TransactionField]()

        if showRawTransaction {
            fields.append(.rawTransaction)
        }

        if let conflictingHash {
            fields.append(.doubleSpend(txHash: transactionHash, conflictingTxHash: conflictingHash))
        }

        if let lockState = lockState(lastBlockTimestamp: lastBlockInfo?.timestamp) {
            fields.append(.lockInfo(lockState: lockState))
        }

        if let memo {
            fields.append(.memo(text: memo))
        }

        return fields
    }
}

struct TransactionLockState {
    let locked: Bool
    let date: Date
}

extension TransactionLockState: Equatable {
    public static func == (lhs: TransactionLockState, rhs: TransactionLockState) -> Bool {
        lhs.locked == rhs.locked && lhs.date == rhs.date
    }
}

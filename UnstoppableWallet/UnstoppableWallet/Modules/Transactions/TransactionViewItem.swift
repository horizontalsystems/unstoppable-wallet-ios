import Foundation
import DeepDiff
import CurrencyKit

struct TransactionViewItem {
    let wallet: Wallet
    let record: TransactionRecord
    let transactionHash: String
    let coinValue: CoinValue
    var currencyValue: CurrencyValue?
    let type: TransactionType
    let date: Date
    let status: TransactionStatus
    let lockState: TransactionLockState?
    let conflictingTxHash: String?

    var isPending: Bool {
        switch status {
        case .pending: return true
        case .processing: return true
        default: return false
        }
    }

    func becomesUnlocked(oldTimestamp: Int?, newTimestamp: Int?) -> Bool {
        guard let lockTime = lockState?.date.timeIntervalSince1970, let newTimestamp = newTimestamp else {
            return false
        }

        return lockTime > Double(oldTimestamp ?? 0) && // was locked
                lockTime <= Double(newTimestamp)       // now unlocked
    }
}

extension TransactionViewItem: DiffAware {

    public var diffId: String {
        record.uid
    }

    public static func compareContent(_ a: TransactionViewItem, _ b: TransactionViewItem) -> Bool {
        a.date == b.date &&
                a.currencyValue == b.currencyValue &&
                a.status == b.status &&
                a.lockState == b.lockState &&
                a.conflictingTxHash == b.conflictingTxHash
    }

}

extension TransactionViewItem: Comparable {

    public static func <(lhs: TransactionViewItem, rhs: TransactionViewItem) -> Bool {
        lhs.record < rhs.record
    }

    public static func ==(lhs: TransactionViewItem, rhs: TransactionViewItem) -> Bool {
        lhs.record == rhs.record
    }

}

extension CurrencyValue {

    var nonZero: CurrencyValue? {
        value == 0 ? nil : self
    }

}
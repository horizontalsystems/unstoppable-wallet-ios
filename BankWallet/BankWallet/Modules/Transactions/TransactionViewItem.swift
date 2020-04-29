import Foundation
import DeepDiff
import CurrencyKit

struct TransactionViewItem {
    let wallet: Wallet
    let record: TransactionRecord
    let transactionHash: String
    let coinValue: CoinValue
    let feeCoinValue: CoinValue?
    var currencyValue: CurrencyValue?
    let from: String?
    let to: String?
    let type: TransactionType
    let date: Date
    let status: TransactionStatus
    var rate: CurrencyValue?
    let lockInfo: TransactionLockInfo?
    let unlocked: Bool
    let conflictingTxHash: String?

    public var isPending: Bool {
        switch status {
        case .pending: return true
        case .processing: return true
        default: return false
        }
    }

    init(wallet: Wallet, record: TransactionRecord, transactionHash: String, coinValue: CoinValue, feeCoinValue: CoinValue?,
         currencyValue: CurrencyValue?, from: String?, to: String?, type: TransactionType,
         date: Date, status: TransactionStatus, rate: CurrencyValue?, lockInfo: TransactionLockInfo?, unlocked: Bool = true, conflictingTxHash: String?) {
        self.wallet = wallet
        self.record = record
        self.transactionHash = transactionHash
        self.coinValue = coinValue
        self.feeCoinValue = feeCoinValue
        self.currencyValue = currencyValue
        self.from = from
        self.to = to
        self.type = type
        self.date = date
        self.status = status
        self.rate = rate
        self.lockInfo = lockInfo
        self.unlocked = unlocked
        self.conflictingTxHash = conflictingTxHash
    }

    func becomesUnlocked(oldTimestamp: Int?, newTimestamp: Int?) -> Bool {
        guard let lockTime = lockInfo?.lockedUntil.timeIntervalSince1970,
              let newTimestamp = newTimestamp else {
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
                a.rate == b.rate &&
                a.status == b.status &&
                a.unlocked == b.unlocked &&
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
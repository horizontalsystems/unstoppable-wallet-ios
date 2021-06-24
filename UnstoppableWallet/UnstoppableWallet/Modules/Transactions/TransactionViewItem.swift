import Foundation
import DeepDiff
import CurrencyKit

struct TransactionViewItem {
    let wallet: Wallet
    let record: TransactionRecord
    let type: TransactionType
    let date: Date
    let status: TransactionStatus

    var mainAmountCurrencyValue: CurrencyValue?
}

extension TransactionViewItem: DiffAware {

    public var diffId: String {
        record.uid
    }

    public static func compareContent(_ a: TransactionViewItem, _ b: TransactionViewItem) -> Bool {
        a.date == b.date && a.status == b.status &&
                a.mainAmountCurrencyValue == b.mainAmountCurrencyValue && a.type.compareContent(b.type)
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

extension TransactionViewItem: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(record.uid)
    }

}

extension CurrencyValue {

    var nonZero: CurrencyValue? {
        value == 0 ? nil : self
    }

}

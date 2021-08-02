import Foundation
import DeepDiff
import CurrencyKit

struct TransactionViewItem {
    let wallet: TransactionWallet
    let record: TransactionRecord
    let type: TransactionType
    let date: Date
    let status: TransactionStatus

    var mainAmountCurrencyString: String?
}

extension TransactionViewItem: DiffAware {

    public var diffId: String {
        record.uid
    }

    public static func compareContent(_ a: TransactionViewItem, _ b: TransactionViewItem) -> Bool {
        a.date == b.date && a.status == b.status &&
                a.mainAmountCurrencyString == b.mainAmountCurrencyString && a.type.compareContent(b.type)
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

extension TransactionViewItem {

    enum TransactionType {
        case incoming(from: String?, amount: String, lockState: TransactionLockState?, conflictingTxHash: String?)
        case outgoing(to: String?, amount: String, lockState: TransactionLockState?, conflictingTxHash: String?, sentToSelf: Bool)
        case approve(spender: String, amount: String, isMaxAmount: Bool, coinCode: String)
        case swap(exchangeAddress: String, amountIn: String, amountOut: String?, foreignRecipient: Bool)
        case contractCall(contractAddress: String, blockchain: String, method: String?)
        case contractCreation
        
        func compareContent(_ type: TransactionType) -> Bool {
            switch (self, type) {
                case (.incoming(_, _, let lhsLockState, let lhsConflictingTxHash), .incoming(_, _, let rhsLockState, let rhsConflictingTxHash)):
                    return lhsLockState == rhsLockState && lhsConflictingTxHash == rhsConflictingTxHash
                    
                case (.outgoing(_, _, let lhsLockState, let lhsConflictingTxHash, _), .outgoing(_, _, let rhsLockState, let rhsConflictingTxHash, _)):
                    return lhsLockState == rhsLockState && lhsConflictingTxHash == rhsConflictingTxHash
                    
                case (.approve, .approve):
                    return true
                    
                case (.swap, .swap):
                    return true
                    
                case (.contractCall, .contractCall):
                    return true
                    
                case (.contractCreation, .contractCreation):
                    return true
                    
                default: return false
            }
        }
        
    }

}

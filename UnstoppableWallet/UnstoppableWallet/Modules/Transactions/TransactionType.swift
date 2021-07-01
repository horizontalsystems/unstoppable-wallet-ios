import Foundation
import CoinKit

enum TransactionType {
    case incoming(from: String?, coinValue: CoinValue, lockState: TransactionLockState?, conflictingTxHash: String?)
    case outgoing(to: String?, coinValue: CoinValue, lockState: TransactionLockState?, conflictingTxHash: String?, sentToSelf: Bool)
    case approve(spender: String, coinValue: CoinValue)
    case swap(exchangeAddress: String, valueIn: CoinValue, valueOut: CoinValue?)
    case contractCall(contractAddress: String, method: String?)
    case contractCreation

    var coinValue: CoinValue? {
        switch self {
        case .incoming(_, let coinValue, _, _): return coinValue
        case .outgoing(_, let coinValue, _, _, _): return coinValue
        case .approve(_, let coinValue): return coinValue
        default: return nil
        }
    }

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

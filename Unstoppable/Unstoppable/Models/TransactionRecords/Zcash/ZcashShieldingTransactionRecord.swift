import Foundation
import MarketKit

class ZcashShieldingTransactionRecord: BitcoinTransactionRecord {
    let value: AppValue
    let direction: Direction

    init(token: Token, source: TransactionSource, uid: String, transactionHash: String, transactionIndex: Int, blockHeight: Int?, confirmationsThreshold: Int?, date: Date, fee: Decimal?, failed: Bool,
         lockInfo: TransactionLockInfo?, conflictingHash: String?, showRawTransaction: Bool,
         amount: Decimal, direction: Direction, memo: String? = nil)
    {
        value = AppValue(token: token, value: Decimal(sign: .plus, exponent: amount.exponent, significand: amount.significand))
        self.direction = direction

        super.init(
            source: source,
            uid: uid,
            transactionHash: transactionHash,
            transactionIndex: transactionIndex,
            blockHeight: blockHeight,
            confirmationsThreshold: confirmationsThreshold,
            date: date,
            fee: fee.flatMap { AppValue(token: token, value: $0) },
            failed: failed,
            lockInfo: lockInfo,
            conflictingHash: conflictingHash,
            showRawTransaction: showRawTransaction,
            memo: memo
        )
    }

    override var mainValue: AppValue? {
        value
    }

    enum Direction {
        case shield, unshield

        init(direction: ZcashTransactionWrapper.Direction) {
            switch direction {
            case .shield: self = .shield
            case .unshield: self = .unshield
            }
        }

        var txTitle: String {
            switch self {
            case .shield: return "transactions.shield".localized
            case .unshield: return "transactions.unshield".localized
            }
        }

        var txIconName: String {
            switch self {
            case .shield: return "shield_24"
            case .unshield: return "shield_off_24"
            }
        }
    }
}

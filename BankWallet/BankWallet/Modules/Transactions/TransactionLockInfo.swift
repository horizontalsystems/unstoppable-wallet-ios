import Foundation
import Hodler

struct TransactionLockInfo {
    let lockedUntil: Date
    let originalAddress: String
    let lockedValue: Decimal

    init?(lockedUntil: Date, originalAddress: String, lockedValue: Decimal) {
        self.lockedUntil = lockedUntil
        self.originalAddress = originalAddress
        self.lockedValue = lockedValue
    }

}

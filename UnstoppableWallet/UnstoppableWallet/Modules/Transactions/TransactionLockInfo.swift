import Foundation
import Hodler

struct TransactionLockInfo {
    let lockedUntil: Date
    let originalAddress: String

    init(lockedUntil: Date, originalAddress: String) {
        self.lockedUntil = lockedUntil
        self.originalAddress = originalAddress
    }

}

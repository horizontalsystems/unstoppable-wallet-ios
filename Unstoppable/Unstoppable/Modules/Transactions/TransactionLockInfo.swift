import Foundation
import Hodler

struct TransactionLockInfo {
    let lockedUntil: Date
    let originalAddress: String
    let lockTimeInterval: HodlerPlugin.LockTimeInterval

    init(lockedUntil: Date, originalAddress: String, lockTimeInterval: HodlerPlugin.LockTimeInterval) {
        self.lockedUntil = lockedUntil
        self.originalAddress = originalAddress
        self.lockTimeInterval = lockTimeInterval
    }
}

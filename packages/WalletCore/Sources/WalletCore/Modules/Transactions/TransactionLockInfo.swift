import Foundation
import Hodler

struct TransactionLockInfo {
    let lockedUntil: Date
    let originalAddress: String
    let lockTimeInterval: HodlerPlugin.LockTimeInterval
}

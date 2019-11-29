import Foundation
import Hodler

struct TransactionLockInfo {
    let lockedUntil: Date
    let originalAddress: String
    let lockedValue: Decimal

    init?(pluginId: UInt8?, pluginData: Any?) {
        guard let pluginId = pluginId, let pluginData = pluginData,
              pluginId == HodlerPlugin.id, let hodlerOutputData = pluginData as? HodlerOutputData,
              let lockUntil = hodlerOutputData.approximateUnlockTime else {
            return nil
        }

        lockedUntil = Date(timeIntervalSince1970: Double(lockUntil))
        originalAddress = hodlerOutputData.addressString
        lockedValue = Decimal(hodlerOutputData.lockedValue)
    }

}

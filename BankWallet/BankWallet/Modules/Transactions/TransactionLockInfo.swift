import Foundation
import Hodler

struct TransactionLockInfo {
    let lockedUntil: Date
    let originalAddress: String

    init?(pluginData: [UInt8: Any]?) {
        guard let pluginData = pluginData,
              let hodlerPluginData = pluginData[HodlerPlugin.id],
              let hodlerOutputData = hodlerPluginData as? HodlerOutputData,
              let lockUntil = hodlerOutputData.approximateUnlockTime else {
            return nil
        }

        lockedUntil = Date(timeIntervalSince1970: Double(lockUntil))
        originalAddress = hodlerOutputData.addressString
    }

}

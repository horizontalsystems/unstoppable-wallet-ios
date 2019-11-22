import Foundation
import FeeRateKit

struct FeeRate {
    let feeRate: FeeRateKit.FeeRate

    func feeRate(priority: FeeRatePriority) -> Int {
        switch priority {
        case .low:
            return feeRate.low
        case .medium:
            return feeRate.medium
        case .high:
            return feeRate.high
        }
    }

    func duration(priority: FeeRatePriority) -> TimeInterval {
        switch priority {
        case .low:
            return feeRate.lowPriorityDuration
        case .medium:
            return feeRate.mediumPriorityDuration
        case .high:
            return feeRate.highPriorityDuration
        }

    }

}

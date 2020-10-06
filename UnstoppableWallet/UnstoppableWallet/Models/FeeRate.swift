import Foundation
import FeeRateKit

struct FeeRate {
    let feeRate: FeeRateKit.FeeRate

    func feeRate(priority: FeeRatePriority) -> Int {
        switch priority {
        case .low:
            return feeRate.low
        case .medium, .recommended:
            return feeRate.medium
        case .high:
            return feeRate.high
        case .custom(let value, _):
            return value
        }
    }

    func duration(priority: FeeRatePriority) -> TimeInterval? {
        switch priority {
        case .low:
            return feeRate.lowPriorityDuration
        case .medium, .recommended:
            return feeRate.mediumPriorityDuration
        case .high:
            return feeRate.highPriorityDuration
        case .custom:
            return nil
        }
    }

}

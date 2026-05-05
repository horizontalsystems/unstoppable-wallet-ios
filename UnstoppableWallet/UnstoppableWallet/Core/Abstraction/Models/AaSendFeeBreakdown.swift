import BigInt
import Foundation

struct AaSendFeeBreakdown: Equatable {
    let estimatedFeeInToken: BigUInt
    let requiredPrefundInToken: BigUInt
    let exchangeRate: BigUInt
    let scenario: Scenario

    enum Scenario: Equatable {
        case approvedSend
        case approveAndSend
        case freshDeploy
    }
}

import BigInt
import Foundation

/// Fee breakdown displayed in AA send UI. Carries the base fee in token units
/// (e.g. USDT 6-decimal smallest unit) plus qualifier flags so the View can
/// append "incl. activation + approval" without re-deriving from the scenario.
struct AaSendFeeBreakdown {
    let baseFeeInToken: BigUInt
    let includesActivation: Bool
    let includesApproval: Bool
}

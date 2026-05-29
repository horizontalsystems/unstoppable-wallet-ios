import BigInt
import Foundation

/// Fees for a GasFree submitTransfer, all denominated in the transferred token (TRC20 stablecoin).
/// Unlike `AaSendFeeBreakdown`, GasFree returns final per-account fees from the service —
/// no exchange-rate scaling is needed. `transferFee` is always charged; `activateFee` only on
/// the very first transfer that deploys the user's BeaconProxy.
struct GasFreeSendFeeBreakdown: Equatable {
    let transferFee: BigUInt
    let activateFee: BigUInt
    let totalFee: BigUInt
    let scenario: Scenario

    enum Scenario: Equatable {
        case transfer
        case activateAndTransfer
    }
}

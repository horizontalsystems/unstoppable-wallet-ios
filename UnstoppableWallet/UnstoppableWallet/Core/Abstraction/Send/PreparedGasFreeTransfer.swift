import BigInt
import Foundation
import MarketKit
import TronKit

/// Result of `GasFreeSender.prepare`. Mirrors `PreparedUserOp` for the GasFree vehicle:
/// holds all fields required to build the final SubmitTransferRequest (signature absent —
/// populated only by `submit(...)`), the TIP-712 `hashToSign`, and the fee breakdown
/// rendered in the confirmation screen.
struct PreparedGasFreeTransfer {
    let token: TronKit.Address
    let serviceProvider: TronKit.Address
    let user: TronKit.Address
    let receiver: TronKit.Address
    let value: BigUInt
    let maxFee: BigUInt
    let deadline: Int64
    let version: Int64
    let nonce: Int64
    let hashToSign: Data
    let feeBreakdown: GasFreeSendFeeBreakdown
    let baseToken: Token
}

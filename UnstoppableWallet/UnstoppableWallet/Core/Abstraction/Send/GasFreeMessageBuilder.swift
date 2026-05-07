import BigInt
import Foundation
import TronKit

/// Pure assembly of a GasFree TIP-712 PermitTransfer message + its hash.
/// No I/O — all inputs are passed in, including provider-fetched fees and nonce.
/// Lives outside `GasFreeSender` so the policy (deadline, version) is changeable
/// in one place and unit-testable without network.
enum GasFreeMessageBuilder {
    static let permitVersion: Int64 = 1
    static let defaultDeadlineDuration: TimeInterval = 600

    static func feeBreakdown(asset: GasFreeProvider.AccountInfo.Asset, isActive: Bool) -> GasFreeSendFeeBreakdown {
        let scenario: GasFreeSendFeeBreakdown.Scenario = isActive ? .transfer : .activateAndTransfer
        let activateFee: BigUInt = isActive ? 0 : asset.activateFee
        return GasFreeSendFeeBreakdown(
            transferFee: asset.transferFee,
            activateFee: activateFee,
            totalFee: asset.transferFee + activateFee,
            scenario: scenario
        )
    }

    /// Build the TIP-712 message + final hash for a single transfer.
    /// `now` is injected for testability; production callers pass `Date()`.
    static func makeMessage(
        token: TronKit.Address,
        serviceProvider: TronKit.Address,
        controller: TronKit.Address,
        receiver: TronKit.Address,
        value: BigUInt,
        maxFee: BigUInt,
        nonce: Int64,
        now: Date = Date(),
        deadlineDuration: TimeInterval = defaultDeadlineDuration
    ) -> (message: PermitTransfer.Message, hash: Data, deadline: Int64) {
        let deadline = Int64(now.timeIntervalSince1970 + deadlineDuration)

        // Per gasfree.io spec §3.2: `user` is the EOA controller address, NOT the GasFree
        // (BeaconProxy) address. The server recomputes the hash from these fields and
        // ecrecovers the signer; mismatch ⇒ InvalidSignatureException.
        let message = PermitTransfer.Message(
            token: token,
            serviceProvider: serviceProvider,
            user: controller,
            receiver: receiver,
            value: value,
            maxFee: maxFee,
            deadline: deadline,
            version: permitVersion,
            nonce: nonce
        )
        let hash = PermitTransfer.hash(domain: .mainnet(), message: message)
        return (message, hash, deadline)
    }
}

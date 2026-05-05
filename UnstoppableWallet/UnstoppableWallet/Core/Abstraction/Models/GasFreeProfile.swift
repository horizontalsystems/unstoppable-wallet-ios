import Foundation
import TronKit

// Domain wrapper around `GasFreeProfileRecord`. Mirrors the SmartAccountProfile pattern:
// strings on the record side, typed TronKit.Address on the domain side.
//
// Fields:
//   - controllerAddress: user's Tron EOA derived from passkey-PRF secp256k1 privkey.
//                        Same value carries three names across the system: this field,
//                        the TIP-712 message `user` field, and the on-chain "owner" of
//                        the GasFree wallet contract.
//   - gasFreeAddress:    locally-derived BeaconProxy CREATE2 address that holds the
//                        user's stablecoin balance and from which transfers originate.
//   - providerId:        GasFree service-provider Tron address (signs paymaster context).
//   - verifyingContract: GasFreeController contract address — the TIP-712 domain
//                        verifyingContract field. Equal to `GasFreeChainAddresses.mainnetFactory`
//                        for v1; persisted per-record for forward compatibility.
struct GasFreeProfile: Equatable, Hashable {
    let accountId: String
    let controllerAddress: TronKit.Address
    let gasFreeAddress: TronKit.Address
    let providerId: TronKit.Address
    let verifyingContract: TronKit.Address
    let implementationVersion: String
    let createdAt: TimeInterval
    let lastVerifiedAt: TimeInterval?
}

extension GasFreeProfile {
    init(record: GasFreeProfileRecord) throws {
        guard let controllerAddress = try? TronKit.Address(address: record.controllerAddress) else {
            throw ConversionError.invalidAddress(field: "controllerAddress")
        }
        guard let gasFreeAddress = try? TronKit.Address(address: record.gasFreeAddress) else {
            throw ConversionError.invalidAddress(field: "gasFreeAddress")
        }
        guard let providerId = try? TronKit.Address(address: record.providerId) else {
            throw ConversionError.invalidAddress(field: "providerId")
        }
        guard let verifyingContract = try? TronKit.Address(address: record.verifyingContract) else {
            throw ConversionError.invalidAddress(field: "verifyingContract")
        }

        self.init(
            accountId: record.accountId,
            controllerAddress: controllerAddress,
            gasFreeAddress: gasFreeAddress,
            providerId: providerId,
            verifyingContract: verifyingContract,
            implementationVersion: record.implementationVersion,
            createdAt: record.createdAt,
            lastVerifiedAt: record.lastVerifiedAt
        )
    }

    func toRecord() -> GasFreeProfileRecord {
        GasFreeProfileRecord(
            accountId: accountId,
            controllerAddress: controllerAddress.base58,
            gasFreeAddress: gasFreeAddress.base58,
            providerId: providerId.base58,
            verifyingContract: verifyingContract.base58,
            implementationVersion: implementationVersion,
            createdAt: createdAt,
            lastVerifiedAt: lastVerifiedAt
        )
    }

    enum ConversionError: Error, Equatable {
        case invalidAddress(field: String)
    }
}

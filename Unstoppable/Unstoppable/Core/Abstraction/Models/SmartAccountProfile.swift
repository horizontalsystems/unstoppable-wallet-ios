import BigInt
import EvmKit
import Foundation
import HsExtensions
import MarketKit

struct SmartAccountProfile: Equatable, Hashable {
    let id: String
    let accountId: String
    let implementationVersion: String
    let ownerPublicKeyX: Data
    let ownerPublicKeyY: Data
    let curve: SignatureCurve
    let salt: BigUInt
    let createdAt: TimeInterval
}

extension SmartAccountProfile {
    init(record: SmartAccountProfileRecord) throws {
        guard let x = record.ownerPublicKeyX.hs.hexData else {
            throw ConversionError.invalidHex(field: "ownerPublicKeyX")
        }
        guard let y = record.ownerPublicKeyY.hs.hexData else {
            throw ConversionError.invalidHex(field: "ownerPublicKeyY")
        }
        guard let curve = SignatureCurve(rawValue: record.curve) else {
            throw ConversionError.invalidCurve(field: "curve")
        }
        guard let salt = BigUInt(record.salt) else {
            throw ConversionError.invalidBigUInt(field: "salt")
        }

        self.init(
            id: record.id,
            accountId: record.accountId,
            implementationVersion: record.implementationVersion,
            ownerPublicKeyX: x,
            ownerPublicKeyY: y,
            curve: curve,
            salt: salt,
            createdAt: record.createdAt
        )
    }

    func toRecord() -> SmartAccountProfileRecord {
        SmartAccountProfileRecord(
            id: id,
            accountId: accountId,
            implementationVersion: implementationVersion,
            ownerPublicKeyX: ownerPublicKeyX.hs.hex,
            ownerPublicKeyY: ownerPublicKeyY.hs.hex,
            curve: curve.rawValue,
            salt: String(salt),
            createdAt: createdAt
        )
    }

    func address(blockchainType: BlockchainType) throws -> EvmKit.Address {
        try BarzAddressResolver.resolveLocally(
            publicKeyX: ownerPublicKeyX,
            publicKeyY: ownerPublicKeyY,
            curve: curve,
            blockchainType: blockchainType,
            salt: salt
        )
    }

    enum ConversionError: Error, Equatable {
        case invalidHex(field: String)
        case invalidCurve(field: String)
        case invalidBigUInt(field: String)
    }
}

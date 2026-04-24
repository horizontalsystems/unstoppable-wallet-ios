import BigInt
import EvmKit
import Foundation
import HsExtensions

struct SmartAccountProfile: Equatable, Hashable {
    let id: String
    let accountId: String
    let address: EvmKit.Address
    let implementationVersion: String
    let ownerPublicKeyX: Data
    let ownerPublicKeyY: Data
    let salt: BigUInt
    let createdAt: TimeInterval
}

extension SmartAccountProfile {
    init(record: SmartAccountProfileRecord) throws {
        guard let address = try? EvmKit.Address(hex: record.address) else {
            throw ConversionError.invalidAddress(field: "address")
        }
        guard let x = record.ownerPublicKeyX.hs.hexData else {
            throw ConversionError.invalidHex(field: "ownerPublicKeyX")
        }
        guard let y = record.ownerPublicKeyY.hs.hexData else {
            throw ConversionError.invalidHex(field: "ownerPublicKeyY")
        }
        guard let salt = BigUInt(record.salt) else {
            throw ConversionError.invalidBigUInt(field: "salt")
        }

        self.init(
            id: record.id,
            accountId: record.accountId,
            address: address,
            implementationVersion: record.implementationVersion,
            ownerPublicKeyX: x,
            ownerPublicKeyY: y,
            salt: salt,
            createdAt: record.createdAt
        )
    }

    func toRecord() -> SmartAccountProfileRecord {
        SmartAccountProfileRecord(
            id: id,
            accountId: accountId,
            address: address.eip55,
            implementationVersion: implementationVersion,
            ownerPublicKeyX: ownerPublicKeyX.hs.hex,
            ownerPublicKeyY: ownerPublicKeyY.hs.hex,
            salt: String(salt),
            createdAt: createdAt
        )
    }

    enum ConversionError: Error, Equatable {
        case invalidAddress(field: String)
        case invalidHex(field: String)
        case invalidBigUInt(field: String)
    }
}

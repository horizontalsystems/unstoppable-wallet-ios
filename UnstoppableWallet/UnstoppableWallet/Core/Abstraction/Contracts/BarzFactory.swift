import BigInt
import EvmKit
import Foundation
import HsCryptoKit

enum BarzFactory {
    enum DecodeError: Error {
        case invalidResponse
    }

    enum PublicKeyError: Error {
        case invalidCoordinateLength
    }

    static func encodeCreateAccount(
        verificationFacet: EvmKit.Address,
        owner: Data,
        salt: BigUInt = 0
    ) -> Data {
        AbiEncoder.encodeFunction(
            signature: "createAccount(address,bytes,uint256)",
            arguments: [
                .address(verificationFacet.raw),
                .bytes(owner),
                .uint(salt),
            ]
        )
    }

    static func encodeGetAddress(
        verificationFacet: EvmKit.Address,
        owner: Data,
        salt: BigUInt = 0
    ) -> Data {
        AbiEncoder.encodeFunction(
            signature: "getAddress(address,bytes,uint256)",
            arguments: [
                .address(verificationFacet.raw),
                .bytes(owner),
                .uint(salt),
            ]
        )
    }

    static func decodeGetAddress(_ data: Data) throws -> EvmKit.Address {
        guard let address = ContractMethodHelper.decodeABI(inputArguments: data, argumentTypes: [EvmKit.Address.self]).first as? EvmKit.Address else {
            throw DecodeError.invalidResponse
        }
        return address
    }

    static func encodeSecp256r1PublicKey(x: Data, y: Data) throws -> Data {
        guard x.count == 32, y.count == 32 else {
            throw PublicKeyError.invalidCoordinateLength
        }

        var data = Data([0x04])
        data += x
        data += y
        return data
    }

    /// Encodes a secp256k1 owner for Barz `createAccount` as a 20-byte EOA address.
    ///
    /// Barz `Secp256k1VerificationFacet.isValidKeyType` accepts both 20-byte address
    /// and 65-byte uncompressed pubkey. We use 20-byte to match the canonical Trust
    /// Smart Account derivation in Pimlico permissionless.js (`toTrustSmartAccount`),
    /// keeping our counterfactual addresses interoperable with the standard preset.
    static func encodeSecp256k1Owner(x: Data, y: Data) throws -> Data {
        guard x.count == 32, y.count == 32 else {
            throw PublicKeyError.invalidCoordinateLength
        }

        return Data(Crypto.sha3(x + y).suffix(20))
    }

    static func buildInitCode(
        factory: EvmKit.Address,
        verificationFacet: EvmKit.Address,
        owner: Data,
        salt: BigUInt = 0
    ) -> Data {
        factory.raw + encodeCreateAccount(verificationFacet: verificationFacet, owner: owner, salt: salt)
    }
}

import BigInt
import EvmKit
import Foundation

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
                .address(verificationFacet),
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
                .address(verificationFacet),
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

    static func buildInitCode(
        factory: EvmKit.Address,
        verificationFacet: EvmKit.Address,
        owner: Data,
        salt: BigUInt = 0
    ) -> Data {
        factory.raw + encodeCreateAccount(verificationFacet: verificationFacet, owner: owner, salt: salt)
    }
}

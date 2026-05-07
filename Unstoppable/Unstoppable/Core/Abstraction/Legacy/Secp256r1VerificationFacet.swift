// Legacy — passkey-native AA (P-256 / FCL_ELLIPTIC_ZZ).
// Frozen 2026-04-30: no new accounts of this type are created.
// AaSender still calls dummySignature() until PR-A6 wires EcdsaUserOpSigner.
// TODO-A: delete this Legacy/ folder when strategic decision to drop
// passkey-AA support permanently is made.

import BigInt
import EvmKit
import Foundation

enum Secp256r1VerificationFacet {
    enum SignatureError: Error {
        case invalidComponentLength
    }

    static func encodeInitializeSigner(publicKey: Data) -> Data {
        AbiEncoder.encodeFunction(
            signature: "initializeSigner(bytes)",
            arguments: [.bytes(publicKey)]
        )
    }

    static func packSignature(
        r: Data,
        s: Data,
        authenticatorData: Data,
        clientDataJSONPre: String,
        clientDataJSONPost: String
    ) throws -> Data {
        guard r.count <= 32, s.count <= 32 else {
            throw SignatureError.invalidComponentLength
        }

        return AbiEncoder.encode(
            arguments: [
                .uint(BigUInt(r)),
                .uint(BigUInt(s)),
                .bytes(authenticatorData),
                .string(clientDataJSONPre),
                .string(clientDataJSONPost),
            ]
        )
    }

    static func dummySignature() -> Data {
        try! packSignature(
            r: Data(repeating: 0, count: 32),
            s: Data(repeating: 0, count: 32),
            authenticatorData: Data(repeating: 0, count: 37),
            clientDataJSONPre: #"{"type":"webauthn.get","challenge":""#,
            clientDataJSONPost: #"","origin":"https://unstoppable.money","crossOrigin":false}"#
        )
    }
}

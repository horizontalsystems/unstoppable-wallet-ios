import CryptoKit
import Foundation

// Glue between SmartAccountPasskeyManager (raw WebAuthn assertion) and the bytes
// that go into UserOperation.signature for Barz on-chain verification.
//
// Pipeline:
//   1. assertForSigning(credentialID, challenge: userOpHash) → WebAuthnSignature
//   2. Decode DER ECDSA via CryptoKit P256 → raw 64 bytes (r || s)
//   3. Split clientDataJSON around base64url(userOpHash) → (pre, post)
//   4. Secp256r1VerificationFacet.packSignature(r, s, authenticatorData, pre, post)
enum PasskeyUserOpSigner {
    enum SigningError: Error {
        case malformedDerSignature
        case clientDataJSONNotUTF8
        case clientDataJSONMissingChallenge
    }

    static func sign(userOpHash: Data, credentialID: Data, passkeyManager: SmartAccountPasskeyManager) async throws -> Data {
        let webAuthn = try await passkeyManager.assertForSigning(
            credentialID: credentialID,
            challenge: userOpHash
        )

        let (r, s) = try decodeDerEcdsaSignature(webAuthn.signature)
        let (pre, post) = try splitClientDataJSON(webAuthn.clientDataJSON, challenge: userOpHash)

        return try Secp256r1VerificationFacet.packSignature(
            r: r,
            s: s,
            authenticatorData: webAuthn.authenticatorData,
            clientDataJSONPre: pre,
            clientDataJSONPost: post
        )
    }
}

// MARK: - DER ECDSA decoding

extension PasskeyUserOpSigner {
    /// Decodes a DER-encoded P-256 (secp256r1) ECDSA signature — as returned by Apple's
    /// passkey authenticator — into raw 32-byte `(r, s)` components.
    ///
    /// Uses CryptoKit's `P256.Signing.ECDSASignature.rawRepresentation`, which is the canonical
    /// 64-byte concatenation `r (32 BE) || s (32 BE)` for the right elliptic curve.
    static func decodeDerEcdsaSignature(_ der: Data) throws -> (r: Data, s: Data) {
        do {
            let signature = try P256.Signing.ECDSASignature(derRepresentation: der)
            let raw = signature.rawRepresentation
            guard raw.count == 64 else {
                throw SigningError.malformedDerSignature
            }
            return (raw.prefix(32), raw.suffix(32))
        } catch {
            throw SigningError.malformedDerSignature
        }
    }
}

// MARK: - clientDataJSON split

extension PasskeyUserOpSigner {
    /// Splits clientDataJSON into the segment before the challenge value and the segment after,
    /// so the on-chain Barz verifier can reconstruct the full JSON given the userOpHash.
    ///
    /// clientDataJSON looks like:
    ///   {"type":"webauthn.get","challenge":"<base64url>","origin":"...","crossOrigin":false}
    ///
    /// pre  ends with `"challenge":"`
    /// post starts with `","origin":...`
    static func splitClientDataJSON(_ data: Data, challenge: Data) throws -> (pre: String, post: String) {
        guard let json = String(data: data, encoding: .utf8) else {
            throw SigningError.clientDataJSONNotUTF8
        }
        let challengeString = challenge.base64UrlEncodedString()
        guard let range = json.range(of: challengeString) else {
            throw SigningError.clientDataJSONMissingChallenge
        }
        return (String(json[..<range.lowerBound]), String(json[range.upperBound...]))
    }
}

// MARK: - Helpers

private extension Data {
    func base64UrlEncodedString() -> String {
        var s = base64EncodedString()
        s = s.replacingOccurrences(of: "+", with: "-")
        s = s.replacingOccurrences(of: "/", with: "_")
        s = s.replacingOccurrences(of: "=", with: "")
        return s
    }
}

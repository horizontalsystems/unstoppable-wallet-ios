import EvmKit
import Foundation
import HdWalletKit

/// Signs UserOp hashes for Barz `Secp256k1VerificationFacet` using the passkey-derived
/// mnemonic. PrivKey is reconstructed on every call, used for one signature, and discarded
/// — never persisted to disk.
///
/// Q1 verified 2026-04-29: `signer.signed(message: userOpHash, isLegacy: false)` produces
/// a 65-byte ECDSA signature recoverable to the EOA via the same EIP-191 prefixed-hash
/// flow that Barz computes via `toEthSignedMessageHash`. See
/// `AppTests/Abstraction/Send/EcdsaSignerRoundtripTests.swift`.
enum EcdsaUserOpSigner {
    enum SigningError: Error {
        case seedDerivationFailed
    }

    /// Triggers Face ID, fetches passkey-derived mnemonic via PRF, derives secp256k1
    /// privKey, signs the UserOp hash, and returns the 65-byte signature.
    static func signViaPasskey(
        credentialID: Data,
        userOpHash: Data,
        passkeyManager: PasskeyManager,
        chain: EvmKit.Chain
    ) async throws -> Data {
        let passkey = try await passkeyManager.loginWith(credentialID: credentialID)
        guard let seed = Mnemonic.seed(mnemonic: passkey.mnemonic, passphrase: "") else {
            throw SigningError.seedDerivationFailed
        }
        let privateKey = try Signer.privateKey(seed: seed, chain: chain)
        let signer = Signer.instance(privateKey: privateKey, chain: chain)
        return try signer.signed(message: userOpHash, isLegacy: false)
    }

    /// 65 bytes of zeros. Valid format for gas estimation — `ecrecover` returns a
    /// garbage address that the facet rejects, but ECDSA verification gas profile
    /// is independent of signature values. Replaces the legacy ~388-byte WebAuthn
    /// dummy (`Secp256r1VerificationFacet.dummySignature()`) and frees up calldata gas.
    static func dummySignature() -> Data {
        Data(repeating: 0, count: 65)
    }
}

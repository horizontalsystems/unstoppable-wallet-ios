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
        case invalidUserOpHash
    }

    private static let estimationDummyPrivateKey = Data(repeating: 0, count: 31) + Data([0x01])

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
        return try normalizeRecoveryId(signer.signed(message: userOpHash, isLegacy: false))
    }

    /// Recoverable 65-byte ECDSA signature for gas estimation.
    ///
    /// Barz Secp256k1VerificationFacet calls OpenZeppelin ECDSA.recover during
    /// validation. An all-zero signature reverts before the account can return
    /// signature-failed validation data, so Pimlico reports AA23. A deterministic
    /// dummy-key signature is structurally valid and keeps validation non-reverting.
    static func dummySignature(userOpHash: Data, chain: EvmKit.Chain) throws -> Data {
        guard userOpHash.count == 32 else {
            throw SigningError.invalidUserOpHash
        }

        let signer = Signer.instance(privateKey: estimationDummyPrivateKey, chain: chain)
        return try normalizeRecoveryId(signer.signed(message: userOpHash, isLegacy: false))
    }

    private static func normalizeRecoveryId(_ signature: Data) -> Data {
        guard signature.count == 65, let recoveryId = signature.last, recoveryId < 2 else {
            return signature
        }

        var normalized = signature
        normalized[64] = recoveryId + 27
        return normalized
    }
}

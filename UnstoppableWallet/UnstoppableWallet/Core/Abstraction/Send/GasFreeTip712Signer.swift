import EvmKit
import Foundation
import HdWalletKit
import TronKit

/// Signs TIP-712 PermitTransfer message hashes for the GasFree.io controller.
///
/// Derives the Tron EOA secp256k1 privkey from the PRF mnemonic via canonical
/// Tron BIP44 m/44'/195'/0'/0/0 — same path used in CreateSmartAccountService
/// for the controller address. PrivKey lives only in the call scope.
///
/// The input is the already-computed EIP-712 hash, so we sign it raw (`isLegacy: true`
/// skips the `\x19Ethereum Signed Message:\n` prefix that EvmKit otherwise applies).
/// Recovery id is normalised to {27,28} to match the OpenZeppelin ECDSA.recover
/// convention used by Tron's GasFreeController.
enum GasFreeTip712Signer {
    enum SigningError: Error {
        case seedDerivationFailed
    }

    static func signViaPasskey(
        credentialID: Data,
        messageHash: Data,
        passkeyManager: PasskeyManager
    ) async throws -> Data {
        let passkey = try await passkeyManager.loginWith(credentialID: credentialID)
        guard let seed = Mnemonic.seed(mnemonic: passkey.mnemonic, passphrase: "") else {
            throw SigningError.seedDerivationFailed
        }
        let privateKey = try TronKit.Signer.privateKey(seed: seed)
        return try sign(messageHash: messageHash, privateKey: privateKey)
    }

    /// Pure helper: given a 32-byte hash and a privkey, returns a 65-byte ECDSA
    /// signature with recovery id normalised to {27,28}. Exposed for testability.
    static func sign(messageHash: Data, privateKey: Data) throws -> Data {
        let signer = Signer.instance(privateKey: privateKey, chain: .ethereum)
        let raw = try signer.signed(message: messageHash, isLegacy: true)
        return normalizeRecoveryId(raw)
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

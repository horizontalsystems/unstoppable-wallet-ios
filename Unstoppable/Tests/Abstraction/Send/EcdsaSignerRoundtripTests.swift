import EvmKit
import HdWalletKit
import HsCryptoKit
import HsExtensions
@testable import Unstoppable
import XCTest

/// Spike PR-A1, Q1 — empirical verification that
/// `EvmKit.Signer.signed(message: userOpHash, isLegacy: false)` produces a
/// signature recoverable to the signer's EOA via the same prefixed hash that
/// Barz `Secp256k1VerificationFacet.validateSignature` uses on-chain.
///
/// Acceptance: signature is 65 bytes; recovered address equals derived EOA.
/// If green → v1 spec can lock `signer.signed(message:, isLegacy: false)` as
/// the production signing primitive for ECDSA AA UserOps.
///
/// See `docs/superpowers/spikes/2026-04-29-pr-a1-signer-and-create2-spike.md`.
final class EcdsaSignerRoundtripTests: XCTestCase {
    /// Hardhat's standard test mnemonic. Account #0 (m/44'/60'/0'/0/0) is the
    /// canonical fixture EOA across the entire EVM tooling ecosystem.
    private let hardhatMnemonic = [
        "test", "test", "test", "test", "test", "test",
        "test", "test", "test", "test", "test", "junk",
    ]

    /// Hardhat account #0 derived from the above mnemonic at m/44'/60'/0'/0/0.
    private let expectedEoaHex = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

    /// Q1: signed(message:) recovers to EOA via toEthSignedMessageHash logic
    func testSignedMessageRecoversToEoa() throws {
        let seed = try XCTUnwrap(Mnemonic.seed(mnemonic: hardhatMnemonic, passphrase: ""))
        let privateKey = try Signer.privateKey(seed: seed, chain: .ethereum)

        let expectedEoa = try EvmKit.Address(hex: expectedEoaHex)
        let derivedEoa = Signer.address(privateKey: privateKey)
        XCTAssertEqual(derivedEoa, expectedEoa, "Derived EOA must match hardhat account #0 — confirms BIP44 m/44'/60'/0'/0/0 derivation")

        let signer = Signer.instance(privateKey: privateKey, chain: .ethereum)

        // Arbitrary deterministic test userOpHash (any 32-byte value works).
        let userOpHash = "b612aae4361cf5db4bcf12d05a7eeb4228b89ffbd23438bc5a77dea6bb266b48".hs.hexData!
        XCTAssertEqual(userOpHash.count, 32)

        let signature = try signer.signed(message: userOpHash, isLegacy: false)
        XCTAssertEqual(signature.count, 65, "ECDSA signature must be 65 bytes (r || s || v)")

        // Reproduce Barz Secp256k1VerificationFacet.validateSignature on-chain logic:
        //   bytes32 hash = userOpHash.toEthSignedMessageHash();
        //   isValid = (signer != hash.recover(userOp.signature));
        // toEthSignedMessageHash() prepends "\x19Ethereum Signed Message:\n32" and re-hashes.
        // Client (EthSigner.prefixed) does the same. Both arrive at the same prefixed hash.
        let prefix = "\u{0019}Ethereum Signed Message:\n\(userOpHash.count)"
        let prefixData = try XCTUnwrap(prefix.data(using: .utf8))
        let prefixedHash = Crypto.sha3(prefixData + userOpHash)

        let recoveredPubkey = try XCTUnwrap(
            Crypto.ellipticPublicKey(signature: signature, of: prefixedHash, compressed: false),
            "Signature must recover a public key from the prefixed hash"
        )

        // EVM address = keccak256(uncompressed pubkey without 0x04 prefix).suffix(20)
        let pubkeyWithoutPrefix = Data(recoveredPubkey.dropFirst())
        let recoveredAddress = EvmKit.Address(raw: Data(Crypto.sha3(pubkeyWithoutPrefix).suffix(20)))

        XCTAssertEqual(
            recoveredAddress,
            expectedEoa,
            "Signature must recover to EOA — Barz Secp256k1VerificationFacet will accept this signature"
        )
    }

    /// Roundtrip with a different hash to confirm correctness isn't an
    /// accident of one specific test vector.
    func testDifferentHashRecoversToSameEoa() throws {
        let seed = try XCTUnwrap(Mnemonic.seed(mnemonic: hardhatMnemonic, passphrase: ""))
        let privateKey = try Signer.privateKey(seed: seed, chain: .ethereum)
        let signer = Signer.instance(privateKey: privateKey, chain: .ethereum)
        let expectedEoa = Signer.address(privateKey: privateKey)

        let hash = "0000000000000000000000000000000000000000000000000000000000000001".hs.hexData!
        let signature = try signer.signed(message: hash, isLegacy: false)
        XCTAssertEqual(signature.count, 65)

        let prefix = "\u{0019}Ethereum Signed Message:\n\(hash.count)"
        let prefixData = try XCTUnwrap(prefix.data(using: .utf8))
        let prefixedHash = Crypto.sha3(prefixData + hash)

        let recoveredPubkey = try XCTUnwrap(Crypto.ellipticPublicKey(signature: signature, of: prefixedHash, compressed: false))
        let recoveredAddress = EvmKit.Address(raw: Data(Crypto.sha3(Data(recoveredPubkey.dropFirst())).suffix(20)))

        XCTAssertEqual(recoveredAddress, expectedEoa)
    }

    /// `isLegacy: true` skips EIP-191 prefixing and signs the raw hash.
    /// Confirms our default `isLegacy: false` is the right choice for Barz
    /// (which expects the prefixed-hash flow).
    func testLegacyModeProducesDifferentSignatureAndDoesNotMatchPrefixedFlow() throws {
        let seed = try XCTUnwrap(Mnemonic.seed(mnemonic: hardhatMnemonic, passphrase: ""))
        let privateKey = try Signer.privateKey(seed: seed, chain: .ethereum)
        let signer = Signer.instance(privateKey: privateKey, chain: .ethereum)

        let userOpHash = "b612aae4361cf5db4bcf12d05a7eeb4228b89ffbd23438bc5a77dea6bb266b48".hs.hexData!

        let prefixedSignature = try signer.signed(message: userOpHash, isLegacy: false)
        let rawSignature = try signer.signed(message: userOpHash, isLegacy: true)

        XCTAssertNotEqual(prefixedSignature, rawSignature, "Legacy mode signs raw hash, default mode signs prefixed hash — must differ")

        // Legacy signature recovers from raw userOpHash, NOT from prefixed.
        // Confirms semantic difference and validates our default-mode choice for Barz.
        let recoveredFromRaw = try XCTUnwrap(Crypto.ellipticPublicKey(signature: rawSignature, of: userOpHash, compressed: false))
        let recoveredAddressFromRaw = EvmKit.Address(raw: Data(Crypto.sha3(Data(recoveredFromRaw.dropFirst())).suffix(20)))
        let expectedEoa = Signer.address(privateKey: privateKey)
        XCTAssertEqual(recoveredAddressFromRaw, expectedEoa)
    }
}

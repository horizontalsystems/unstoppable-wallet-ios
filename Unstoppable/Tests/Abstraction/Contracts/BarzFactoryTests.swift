import EvmKit
import HdWalletKit
import HsCryptoKit
import HsExtensions
@testable import Unstoppable
import XCTest

final class BarzFactoryTests: XCTestCase {
    func testCreateAccountEncoding() {
        let data = BarzFactory.encodeCreateAccount(
            verificationFacet: ChainAddresses.secp256r1VerificationFacet,
            owner: ownerPublicKey()
        )

        XCTAssertEqual(
            data.hs.hex,
            "296601cd000000000000000000000000ee1af8e967ec04c84711842796a5e714d2fd33e6000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000041041111111111111111111111111111111111111111111111111111111111111111222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000"
        )
    }

    func testGetAddressEncoding() {
        let data = BarzFactory.encodeGetAddress(
            verificationFacet: ChainAddresses.secp256r1VerificationFacet,
            owner: ownerPublicKey()
        )

        XCTAssertEqual(
            data.hs.hex,
            "c8a7adf5000000000000000000000000ee1af8e967ec04c84711842796a5e714d2fd33e6000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000041041111111111111111111111111111111111111111111111111111111111111111222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000"
        )
    }

    func testDecodeGetAddress() throws {
        let address = try BarzFactory.decodeGetAddress(
            "0000000000000000000000001234567890abcdef1234567890abcdef12345678".hs.hexData!
        )

        XCTAssertEqual(address, try EvmKit.Address(hex: "0x1234567890abcdef1234567890abcdef12345678"))
    }

    func testSecp256r1PubkeyFormat() throws {
        let publicKey = try BarzFactory.encodeSecp256r1PublicKey(
            x: Data(repeating: 0x11, count: 32),
            y: Data(repeating: 0x22, count: 32)
        )

        XCTAssertEqual(publicKey, ownerPublicKey())
    }

    /// encodeSecp256k1Owner(x:y:) derives 20-byte EOA address from the secp256k1
    /// uncompressed public key halves. Cross-check: hardhat test mnemonic at
    /// m/44'/60'/0'/0/0 yields EOA 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266.
    /// The encoded owner must equal Signer.address(privateKey:) for the same key.
    func testEncodeSecp256k1Owner_matchesSignerAddress() throws {
        let mnemonic = [
            "test", "test", "test", "test", "test", "test",
            "test", "test", "test", "test", "test", "junk",
        ]
        let seed = try XCTUnwrap(Mnemonic.seed(mnemonic: mnemonic, passphrase: ""))
        let privateKey = try Signer.privateKey(seed: seed, chain: .ethereum)

        let pubkey = Crypto.publicKey(privateKey: privateKey, compressed: false)
        XCTAssertEqual(pubkey.count, 65, "uncompressed secp256k1 pubkey must be 65 bytes")
        XCTAssertEqual(pubkey.first, 0x04, "uncompressed prefix")

        let X = Data(pubkey.dropFirst().prefix(32))
        let Y = Data(pubkey.dropFirst().suffix(32))

        let encoded = try BarzFactory.encodeSecp256k1Owner(x: X, y: Y)

        XCTAssertEqual(encoded.count, 20, "encoded owner must be 20-byte EOA address")
        XCTAssertEqual(EvmKit.Address(raw: encoded), Signer.address(privateKey: privateKey))
        XCTAssertEqual(
            EvmKit.Address(raw: encoded),
            try EvmKit.Address(hex: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"),
            "Hardhat account #0 EOA expected"
        )
    }

    func testEncodeSecp256k1Owner_throwsOnInvalidCoordinateLength() {
        XCTAssertThrowsError(
            try BarzFactory.encodeSecp256k1Owner(x: Data(repeating: 0x11, count: 31), y: Data(repeating: 0x22, count: 32))
        )
        XCTAssertThrowsError(
            try BarzFactory.encodeSecp256k1Owner(x: Data(repeating: 0x11, count: 32), y: Data(repeating: 0x22, count: 31))
        )
    }

    func testBuildInitCode() {
        let data = BarzFactory.buildInitCode(
            factory: ChainAddresses.barzFactory,
            verificationFacet: ChainAddresses.secp256r1VerificationFacet,
            owner: ownerPublicKey()
        )

        XCTAssertEqual(data.prefix(20), ChainAddresses.barzFactory.raw)
        XCTAssertEqual(Data(data.dropFirst(20)).hs.hex, BarzFactory.encodeCreateAccount(
            verificationFacet: ChainAddresses.secp256r1VerificationFacet,
            owner: ownerPublicKey()
        ).hs.hex)
    }

    private func ownerPublicKey() -> Data {
        Data("0411111111111111111111111111111111111111111111111111111111111111112222222222222222222222222222222222222222222222222222222222222222".hs.hexData!)
    }
}

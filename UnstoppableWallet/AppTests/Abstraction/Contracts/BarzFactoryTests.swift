import EvmKit
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

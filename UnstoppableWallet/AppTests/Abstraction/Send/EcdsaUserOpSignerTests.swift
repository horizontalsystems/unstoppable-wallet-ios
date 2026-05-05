import EvmKit
import HsCryptoKit
import HsExtensions
@testable import Unstoppable
import XCTest

/// EcdsaUserOpSigner.signViaPasskey requires interactive Face ID and is exercised
/// end-to-end via manual smoke on testnet. This file covers the deterministic helper.
final class EcdsaUserOpSignerTests: XCTestCase {
    func testDummySignatureIsRecoverable() throws {
        let userOpHash = "b3ba1b2d851f430c8d9d55a64491b97bb3ba1b2d851f430c8d9d55a64491b97b".hs.hexData!
        let dummy = try EcdsaUserOpSigner.dummySignature(userOpHash: userOpHash, chain: .ethereum)

        XCTAssertEqual(dummy.count, 65)
        XCTAssertTrue([27, 28].contains(dummy[64]), "Barz/OpenZeppelin ECDSA.recover expects Ethereum v=27/28")

        let prefix = "\u{0019}Ethereum Signed Message:\n\(userOpHash.count)"
        let prefixData = try XCTUnwrap(prefix.data(using: .utf8))
        let prefixedHash = Crypto.sha3(prefixData + userOpHash)

        var locallyRecoverable = dummy
        locallyRecoverable[64] -= 27

        let recoveredPubkey = Crypto.ellipticPublicKey(signature: locallyRecoverable, of: prefixedHash, compressed: false)
        XCTAssertNotNil(recoveredPubkey)
    }

    func testDummySignatureRejectsMalformedHash() {
        XCTAssertThrowsError(try EcdsaUserOpSigner.dummySignature(userOpHash: Data([0x01]), chain: .ethereum))
    }
}

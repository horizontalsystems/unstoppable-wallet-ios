@testable import Unstoppable
import XCTest

/// EcdsaUserOpSigner.signViaPasskey requires interactive Face ID and is exercised
/// end-to-end via manual smoke on testnet. This file covers the deterministic helper.
final class EcdsaUserOpSignerTests: XCTestCase {
    func testDummySignatureIs65ZeroBytes() {
        let dummy = EcdsaUserOpSigner.dummySignature()

        XCTAssertEqual(dummy.count, 65)
        XCTAssertTrue(dummy.allSatisfy { $0 == 0x00 })
    }
}

import BigInt
import EvmKit
@testable import Unstoppable
import XCTest

/// Tests that `UserOperation -> UserOperationRequest -> UserOperation` preserves all fields.
final class UserOperationRoundTripTests: XCTestCase {
    func testRoundTripPreservesAllFields() throws {
        let original = try UserOperation(
            sender: EvmKit.Address(hex: "0xdeadbeef00000000000000000000000000000000"),
            nonce: BigUInt(42),
            initCode: Data([0xAB, 0xCD]),
            callData: Data([0x01, 0x02, 0x03]),
            callGasLimit: BigUInt(50000),
            verificationGasLimit: BigUInt(100_000),
            preVerificationGas: BigUInt(21000),
            maxFeePerGas: BigUInt(1_500_000_000),
            maxPriorityFeePerGas: BigUInt(500_000_000),
            paymasterAndData: Data([0xFF, 0xEE]),
            signature: Data([0xDE, 0xAD, 0xBE, 0xEF])
        )

        let request = UserOperationRequest(from: original)
        let restored = try request.toUserOperation()

        XCTAssertEqual(original, restored)
    }

    func testEmptyDataFieldsSerializeAs0x() {
        let userOp = UserOperation(
            sender: try! EvmKit.Address(hex: "0x0000000000000000000000000000000000000001"),
            nonce: 0,
            initCode: Data(),
            callData: Data(),
            callGasLimit: 0,
            verificationGasLimit: 0,
            preVerificationGas: 0,
            maxFeePerGas: 0,
            maxPriorityFeePerGas: 0,
            paymasterAndData: Data(),
            signature: Data()
        )

        let request = UserOperationRequest(from: userOp)

        XCTAssertEqual(request.initCode, "0x")
        XCTAssertEqual(request.callData, "0x")
        XCTAssertEqual(request.paymasterAndData, "0x")
        XCTAssertEqual(request.signature, "0x")
        XCTAssertEqual(request.nonce, "0x0")
    }

    func testHexEncodingUintsArePrefixed() {
        let userOp = UserOperation(
            sender: try! EvmKit.Address(hex: "0x0000000000000000000000000000000000000001"),
            nonce: 255,
            initCode: Data(),
            callData: Data(),
            callGasLimit: 16,
            verificationGasLimit: 0,
            preVerificationGas: 0,
            maxFeePerGas: 0,
            maxPriorityFeePerGas: 0,
            paymasterAndData: Data(),
            signature: Data()
        )

        let request = UserOperationRequest(from: userOp)

        XCTAssertEqual(request.nonce, "0xff")
        XCTAssertEqual(request.callGasLimit, "0x10")
    }
}

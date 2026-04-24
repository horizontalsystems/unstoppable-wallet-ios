import BigInt
import EvmKit
import HsCryptoKit
import HsExtensions
@testable import Unstoppable
import XCTest

/// Tests for userOpHash computation (EntryPoint v0.6).
///
/// Real on-chain fixture verification is deferred to Part 2,
/// where the EntryPoint ABI will be available for eth_call-based cross-checks.
final class PackedUserOperationTests: XCTestCase {
    // MARK: - Crypto sanity

    /// Sanity check: our keccak256 (via HsCryptoKit) matches the canonical vector
    /// from the NIST / Keccak test suite: keccak256("abc").
    func testKeccakOfABCMatchesReference() {
        let input = Data("abc".utf8)
        let hex = Crypto.sha3(input).hs.hex
        XCTAssertEqual(hex, "4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45")
    }

    /// keccak256 of empty data == standard "c5d2460186..." vector.
    func testKeccakOfEmptyData() {
        let hex = Crypto.sha3(Data()).hs.hex
        XCTAssertEqual(hex, "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470")
    }

    // MARK: - Inner hash

    /// innerHash output is deterministic for a fixed input.
    func testInnerHashIsDeterministic() {
        let userOp = sampleUserOperation()
        let hash1 = PackedUserOperation.innerHash(userOp: userOp)
        let hash2 = PackedUserOperation.innerHash(userOp: userOp)
        XCTAssertEqual(hash1, hash2)
        XCTAssertEqual(hash1.count, 32)
    }

    /// Changing any single field must change innerHash (sanity on padding).
    func testInnerHashChangesOnNonceChange() {
        let a = sampleUserOperation()
        let b = UserOperation(
            sender: a.sender,
            nonce: a.nonce + 1,
            initCode: a.initCode,
            callData: a.callData,
            callGasLimit: a.callGasLimit,
            verificationGasLimit: a.verificationGasLimit,
            preVerificationGas: a.preVerificationGas,
            maxFeePerGas: a.maxFeePerGas,
            maxPriorityFeePerGas: a.maxPriorityFeePerGas,
            paymasterAndData: a.paymasterAndData,
            signature: a.signature
        )
        XCTAssertNotEqual(
            PackedUserOperation.innerHash(userOp: a),
            PackedUserOperation.innerHash(userOp: b)
        )
    }

    // MARK: - Final userOpHash

    /// userOpHash changes when chainId changes (cross-chain replay protection).
    func testHashChangesOnChainIdChange() {
        let userOp = sampleUserOperation()
        let entryPoint = EntryPointVersion.v06.address

        let hashEth = PackedUserOperation.hash(userOp: userOp, entryPoint: entryPoint, chainId: 1)
        let hashBsc = PackedUserOperation.hash(userOp: userOp, entryPoint: entryPoint, chainId: 56)

        XCTAssertNotEqual(hashEth, hashBsc)
        XCTAssertEqual(hashEth.count, 32)
        XCTAssertEqual(hashBsc.count, 32)
    }

    /// Signature field is excluded from the hash (changing it must not affect userOpHash).
    func testHashIgnoresSignature() {
        let baseOp = sampleUserOperation()
        let modifiedOp = baseOp.withSignature(Data(repeating: 0xFF, count: 128))

        let entryPoint = EntryPointVersion.v06.address
        let hash1 = PackedUserOperation.hash(userOp: baseOp, entryPoint: entryPoint, chainId: 1)
        let hash2 = PackedUserOperation.hash(userOp: modifiedOp, entryPoint: entryPoint, chainId: 1)

        XCTAssertEqual(hash1, hash2)
    }

    // MARK: - Real fixture placeholder (pending Part 2)

    /// Hardcoded from live eth_call to EntryPoint.getUserOpHash() on ETH mainnet.
    func testHashMatchesOnChainReference() throws {
        let expected = Data("edfd7c6c5670154a4999ece69853a5f87368b6f475ce228964ba8f98c5005c8e".hs.hexData!)
        let hash = PackedUserOperation.hash(
            userOp: sampleUserOperation(),
            entryPoint: EntryPointVersion.v06.address,
            chainId: 1
        )

        XCTAssertEqual(hash, expected)
    }

    // MARK: - Helpers

    private func sampleUserOperation() -> UserOperation {
        let sender = try! EvmKit.Address(hex: "0x1234567890abcdef1234567890abcdef12345678")
        return UserOperation(
            sender: sender,
            nonce: 0,
            initCode: Data(),
            callData: Data([0xA9, 0x05, 0x9C, 0xBB]),
            callGasLimit: 50000,
            verificationGasLimit: 100_000,
            preVerificationGas: 21000,
            maxFeePerGas: 1_000_000_000,
            maxPriorityFeePerGas: 1_000_000_000,
            paymasterAndData: Data(),
            signature: Data()
        )
    }
}

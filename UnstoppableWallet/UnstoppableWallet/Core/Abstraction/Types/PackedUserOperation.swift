//
//  Adapted from aa-swift (MIT License)
//  https://github.com/syn-mcj/aa-swift
//  Copyright (c) 2024 aa-swift
//
//  Reimplemented for unstoppable-wallet-ios:
//  - Uses HsCryptoKit.Crypto.sha3 instead of web3.keccak256.
//  - Replaces web3swift ABIEncoder with manual 32-byte padded concatenation
//    (all v0.6 fields are static types, so abi.encode equals raw concat).
//

import BigInt
import EvmKit
import Foundation
import HsCryptoKit

/// Computes ERC-4337 userOpHash for EntryPoint v0.6.
///
/// Formula (per ERC-4337 spec):
///   innerHash = keccak256(abi.encode(
///       sender, nonce,
///       keccak256(initCode), keccak256(callData),
///       callGasLimit, verificationGasLimit, preVerificationGas,
///       maxFeePerGas, maxPriorityFeePerGas,
///       keccak256(paymasterAndData)
///   ))
///   userOpHash = keccak256(abi.encode(innerHash, entryPoint, chainId))
public enum PackedUserOperation {
    /// Size of a single abi-encoded slot in bytes.
    private static let slotSize = 32

    /// Computes the inner hash (first keccak256, without entryPoint and chainId).
    public static func innerHash(userOp: UserOperation) -> Data {
        let encoded = encodeInner(userOp: userOp)
        return Crypto.sha3(encoded)
    }

    /// Computes the final userOpHash, which is what a signer must sign.
    public static func hash(
        userOp: UserOperation,
        entryPoint: EvmKit.Address,
        chainId: BigUInt
    ) -> Data {
        let inner = innerHash(userOp: userOp)

        var outer = Data()
        outer.append(inner)
        outer.append(pad32(address: entryPoint))
        outer.append(pad32(value: chainId))

        return Crypto.sha3(outer)
    }

    // MARK: - Internal encoding

    private static func encodeInner(userOp: UserOperation) -> Data {
        var data = Data()
        data.reserveCapacity(slotSize * 10)

        data.append(pad32(address: userOp.sender))
        data.append(pad32(value: userOp.nonce))
        data.append(Crypto.sha3(userOp.initCode))
        data.append(Crypto.sha3(userOp.callData))
        data.append(pad32(value: userOp.callGasLimit))
        data.append(pad32(value: userOp.verificationGasLimit))
        data.append(pad32(value: userOp.preVerificationGas))
        data.append(pad32(value: userOp.maxFeePerGas))
        data.append(pad32(value: userOp.maxPriorityFeePerGas))
        data.append(Crypto.sha3(userOp.paymasterAndData))

        return data
    }

    // MARK: - Padding helpers

    /// Left-pads an Ethereum address (20 bytes) to a 32-byte slot.
    private static func pad32(address: EvmKit.Address) -> Data {
        pad32(bytes: address.raw)
    }

    /// Encodes a BigUInt as a 32-byte big-endian value.
    private static func pad32(value: BigUInt) -> Data {
        pad32(bytes: value.serialize())
    }

    /// Left-pads raw bytes to 32 bytes. Truncation is a programmer error
    /// (all expected inputs fit in a slot), so we assert in debug.
    private static func pad32(bytes: Data) -> Data {
        if bytes.count == slotSize {
            return bytes
        }
        assert(bytes.count <= slotSize, "value does not fit in 32-byte slot")
        if bytes.count > slotSize {
            return bytes.suffix(slotSize)
        }
        var padded = Data(repeating: 0, count: slotSize - bytes.count)
        padded.append(bytes)
        return padded
    }
}

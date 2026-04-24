//
//  Adapted from aa-swift (MIT License)
//  https://github.com/syn-mcj/aa-swift
//  Copyright (c) 2024 aa-swift
//
//  Reimplemented for unstoppable-wallet-ios:
//  - Reduced to EntryPoint v0.6 fields only (v0.7 paymaster split, v0.8 eip7702 omitted).
//  - Bridges to/from typed UserOperation with EvmKit.Address + BigUInt.
//

import BigInt
import EvmKit
import Foundation
import HsExtensions

/// JSON-RPC wire format for UserOperation v0.6, used in
/// `eth_sendUserOperation`, `eth_estimateUserOperationGas`, etc.
/// All numeric and byte fields are hex-encoded with the `0x` prefix.
public struct UserOperationRequest: Equatable, Encodable {
    public let sender: String
    public let nonce: String
    public let initCode: String
    public let callData: String
    public let callGasLimit: String
    public let verificationGasLimit: String
    public let preVerificationGas: String
    public let maxFeePerGas: String
    public let maxPriorityFeePerGas: String
    public let paymasterAndData: String
    public let signature: String

    public init(
        sender: String,
        nonce: String,
        initCode: String,
        callData: String,
        callGasLimit: String,
        verificationGasLimit: String,
        preVerificationGas: String,
        maxFeePerGas: String,
        maxPriorityFeePerGas: String,
        paymasterAndData: String,
        signature: String
    ) {
        self.sender = sender
        self.nonce = nonce
        self.initCode = initCode
        self.callData = callData
        self.callGasLimit = callGasLimit
        self.verificationGasLimit = verificationGasLimit
        self.preVerificationGas = preVerificationGas
        self.maxFeePerGas = maxFeePerGas
        self.maxPriorityFeePerGas = maxPriorityFeePerGas
        self.paymasterAndData = paymasterAndData
        self.signature = signature
    }
}

public extension UserOperationRequest {
    init(from userOp: UserOperation) {
        self.init(
            sender: HexEncoding.address(userOp.sender),
            nonce: HexEncoding.uint(userOp.nonce),
            initCode: HexEncoding.bytes(userOp.initCode),
            callData: HexEncoding.bytes(userOp.callData),
            callGasLimit: HexEncoding.uint(userOp.callGasLimit),
            verificationGasLimit: HexEncoding.uint(userOp.verificationGasLimit),
            preVerificationGas: HexEncoding.uint(userOp.preVerificationGas),
            maxFeePerGas: HexEncoding.uint(userOp.maxFeePerGas),
            maxPriorityFeePerGas: HexEncoding.uint(userOp.maxPriorityFeePerGas),
            paymasterAndData: HexEncoding.bytes(userOp.paymasterAndData),
            signature: HexEncoding.bytes(userOp.signature)
        )
    }

    func toUserOperation() throws -> UserOperation {
        try UserOperation(
            sender: EvmKit.Address(hex: sender),
            nonce: HexEncoding.decodeUint(nonce),
            initCode: HexEncoding.decodeBytes(initCode),
            callData: HexEncoding.decodeBytes(callData),
            callGasLimit: HexEncoding.decodeUint(callGasLimit),
            verificationGasLimit: HexEncoding.decodeUint(verificationGasLimit),
            preVerificationGas: HexEncoding.decodeUint(preVerificationGas),
            maxFeePerGas: HexEncoding.decodeUint(maxFeePerGas),
            maxPriorityFeePerGas: HexEncoding.decodeUint(maxPriorityFeePerGas),
            paymasterAndData: HexEncoding.decodeBytes(paymasterAndData),
            signature: HexEncoding.decodeBytes(signature)
        )
    }
}

/// Minimal hex encoder/decoder for JSON-RPC wire format.
/// Empty Data encodes as "0x", BigUInt.zero encodes as "0x0".
enum HexEncoding {
    static func address(_ address: EvmKit.Address) -> String {
        address.raw.hs.hex.with0x
    }

    static func uint(_ value: BigUInt) -> String {
        // BigUInt(0) -> "0x0".
        String(value, radix: 16).with0x
    }

    static func bytes(_ data: Data) -> String {
        // Empty Data -> "0x".
        data.hs.hex.with0x
    }

    static func decodeUint(_ string: String) -> BigUInt {
        let trimmed = string.without0x
        if trimmed.isEmpty {
            return 0
        }
        return BigUInt(trimmed, radix: 16) ?? 0
    }

    static func decodeBytes(_ string: String) -> Data {
        let trimmed = string.without0x
        if trimmed.isEmpty {
            return Data()
        }
        return trimmed.hs.hexData ?? Data()
    }
}

private extension String {
    var with0x: String {
        lowercased().hasPrefix("0x") ? self : "0x" + self
    }

    var without0x: String {
        lowercased().hasPrefix("0x") ? String(dropFirst(2)) : self
    }
}

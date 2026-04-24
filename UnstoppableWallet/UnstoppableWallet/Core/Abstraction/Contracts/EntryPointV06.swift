import BigInt
import EvmKit
import Foundation
import HsCryptoKit

enum EntryPointV06 {
    enum DecodeError: Error {
        case invalidResponse
    }

    static let userOperationEventTopic = Crypto.sha3(Data("UserOperationEvent(bytes32,address,address,uint256,bool,uint256,uint256)".utf8))
    static let accountDeployedTopic = Crypto.sha3(Data("AccountDeployed(bytes32,address,address,address)".utf8))

    static func encodeGetNonce(sender: EvmKit.Address, key: BigUInt = 0) -> Data {
        AbiEncoder.encodeFunction(
            signature: "getNonce(address,uint192)",
            arguments: [
                .address(sender),
                .uint(key),
            ]
        )
    }

    static func decodeGetNonce(_ data: Data) throws -> BigUInt {
        guard let nonce = ContractMethodHelper.decodeABI(inputArguments: data, argumentTypes: [BigUInt.self]).first as? BigUInt else {
            throw DecodeError.invalidResponse
        }
        return nonce
    }

    static func encodeGetUserOpHash(_ userOp: UserOperation) -> Data {
        AbiEncoder.encodeFunction(
            signature: "getUserOpHash((address,uint256,bytes,bytes,uint256,uint256,uint256,uint256,uint256,bytes,bytes))",
            arguments: [.tuple(userOperationValues(userOp))]
        )
    }

    static func decodeGetUserOpHash(_ data: Data) throws -> Data {
        guard data.count >= 32 else {
            throw DecodeError.invalidResponse
        }
        return Data(data.prefix(32))
    }

    static func encodeHandleOps(ops: [UserOperation], beneficiary: EvmKit.Address) -> Data {
        AbiEncoder.encodeFunction(
            signature: "handleOps((address,uint256,bytes,bytes,uint256,uint256,uint256,uint256,uint256,bytes,bytes)[],address)",
            arguments: [
                .array(ops.map { .tuple(userOperationValues($0)) }),
                .address(beneficiary),
            ]
        )
    }

    private static func userOperationValues(_ userOp: UserOperation) -> [AbiEncoder.Value] {
        [
            .address(userOp.sender),
            .uint(userOp.nonce),
            .bytes(userOp.initCode),
            .bytes(userOp.callData),
            .uint(userOp.callGasLimit),
            .uint(userOp.verificationGasLimit),
            .uint(userOp.preVerificationGas),
            .uint(userOp.maxFeePerGas),
            .uint(userOp.maxPriorityFeePerGas),
            .bytes(userOp.paymasterAndData),
            .bytes(userOp.signature),
        ]
    }
}

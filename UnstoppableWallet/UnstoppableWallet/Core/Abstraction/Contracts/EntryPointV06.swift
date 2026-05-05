import BigInt
import EvmKit
import Foundation
import HsCryptoKit

enum EntryPointV06 {
    enum DecodeError: Error {
        case invalidResponse
        case unexpectedRevertSelector(Data)
        case revertedWithFailedOp(opIndex: BigUInt, reason: String)
    }

    static let userOperationEventTopic = Crypto.sha3(Data("UserOperationEvent(bytes32,address,address,uint256,bool,uint256,uint256)".utf8))
    static let accountDeployedTopic = Crypto.sha3(Data("AccountDeployed(bytes32,address,address,address)".utf8))

    /// Selector of `error ExecutionResult(uint256 preOpGas, uint256 paid, uint48 validAfter, uint48 validUntil, bool targetSuccess, bytes targetResult)`.
    /// EntryPoint.simulateHandleOp ALWAYS reverts; on success it reverts with this error packed in the revert data.
    static let executionResultSelector = Crypto.sha3(Data("ExecutionResult(uint256,uint256,uint48,uint48,bool,bytes)".utf8)).prefix(4)
    /// Selector of `error FailedOp(uint256 opIndex, string reason)` — returned by simulateHandleOp on validation failure.
    static let failedOpSelector = Crypto.sha3(Data("FailedOp(uint256,string)".utf8)).prefix(4)

    struct SimulationResult: Equatable {
        let preOpGas: BigUInt
        /// `paid` = actualGasCost the EntryPoint would charge from prefund, in wei.
        /// Does NOT include paymaster postOp tail — caller must add `postOpGas × actualGasPrice` separately.
        let paid: BigUInt
    }

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

    static func encodeSimulateHandleOp(_ userOp: UserOperation, target: EvmKit.Address = EvmKit.Address(raw: Data(repeating: 0, count: 20)), targetCallData: Data = Data()) -> Data {
        AbiEncoder.encodeFunction(
            signature: "simulateHandleOp((address,uint256,bytes,bytes,uint256,uint256,uint256,uint256,uint256,bytes,bytes),address,bytes)",
            arguments: [
                .tuple(userOperationValues(userOp)),
                .address(target),
                .bytes(targetCallData),
            ]
        )
    }

    /// Parses revert data from a simulateHandleOp eth_call. Expects the data to start with the
    /// `ExecutionResult` selector (success) — throws `revertedWithFailedOp` on `FailedOp` revert,
    /// `unexpectedRevertSelector` on unknown selectors.
    static func decodeSimulationResult(revertData: Data) throws -> SimulationResult {
        guard revertData.count >= 4 else {
            throw DecodeError.invalidResponse
        }
        let selector = revertData.prefix(4)
        let body = revertData.dropFirst(4)

        if selector == executionResultSelector {
            // Layout: preOpGas(32) | paid(32) | validAfter(32) | validUntil(32) | targetSuccess(32) | targetResultOffset(32) | targetResultLen(32) | targetResultData
            guard body.count >= 64 else {
                throw DecodeError.invalidResponse
            }
            let preOpGas = BigUInt(body[body.startIndex ..< body.startIndex + 32])
            let paid = BigUInt(body[body.startIndex + 32 ..< body.startIndex + 64])
            return SimulationResult(preOpGas: preOpGas, paid: paid)
        }

        if selector == failedOpSelector {
            // Layout: opIndex(32) | reasonOffset(32) | reasonLen(32) | reasonData
            guard body.count >= 96 else {
                throw DecodeError.invalidResponse
            }
            let opIndex = BigUInt(body[body.startIndex ..< body.startIndex + 32])
            let reasonLen = Int(BigUInt(body[body.startIndex + 64 ..< body.startIndex + 96]))
            let reasonStart = body.startIndex + 96
            let reasonEnd = min(reasonStart + reasonLen, body.endIndex)
            let reason = String(data: body[reasonStart ..< reasonEnd], encoding: .utf8) ?? ""
            throw DecodeError.revertedWithFailedOp(opIndex: opIndex, reason: reason)
        }

        throw DecodeError.unexpectedRevertSelector(Data(selector))
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

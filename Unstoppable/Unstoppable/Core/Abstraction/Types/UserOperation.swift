import BigInt
import EvmKit
import Foundation

/// ERC-4337 UserOperation in EntryPoint v0.6 format.
/// All 10 fields are passed as separate values (not packed — packing is only used for hash calculation).
public struct UserOperation: Equatable, Hashable {
    public let sender: EvmKit.Address
    public let nonce: BigUInt
    public let initCode: Data
    public let callData: Data
    public let callGasLimit: BigUInt
    public let verificationGasLimit: BigUInt
    public let preVerificationGas: BigUInt
    public let maxFeePerGas: BigUInt
    public let maxPriorityFeePerGas: BigUInt
    public let paymasterAndData: Data
    public let signature: Data

    public init(
        sender: EvmKit.Address,
        nonce: BigUInt,
        initCode: Data = Data(),
        callData: Data,
        callGasLimit: BigUInt,
        verificationGasLimit: BigUInt,
        preVerificationGas: BigUInt,
        maxFeePerGas: BigUInt,
        maxPriorityFeePerGas: BigUInt,
        paymasterAndData: Data = Data(),
        signature: Data = Data()
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

public extension UserOperation {
    /// Returns a copy with the given signature applied.
    func withSignature(_ signature: Data) -> UserOperation {
        UserOperation(
            sender: sender,
            nonce: nonce,
            initCode: initCode,
            callData: callData,
            callGasLimit: callGasLimit,
            verificationGasLimit: verificationGasLimit,
            preVerificationGas: preVerificationGas,
            maxFeePerGas: maxFeePerGas,
            maxPriorityFeePerGas: maxPriorityFeePerGas,
            paymasterAndData: paymasterAndData,
            signature: signature
        )
    }

    /// Returns a copy with updated gas estimation.
    func withGasEstimate(_ estimate: UserOperationGasEstimate) -> UserOperation {
        UserOperation(
            sender: sender,
            nonce: nonce,
            initCode: initCode,
            callData: callData,
            callGasLimit: estimate.callGasLimit,
            verificationGasLimit: estimate.verificationGasLimit,
            preVerificationGas: estimate.preVerificationGas,
            maxFeePerGas: maxFeePerGas,
            maxPriorityFeePerGas: maxPriorityFeePerGas,
            paymasterAndData: paymasterAndData,
            signature: signature
        )
    }

    /// Returns a copy with paymaster data applied.
    func withPaymasterAndData(_ data: Data) -> UserOperation {
        UserOperation(
            sender: sender,
            nonce: nonce,
            initCode: initCode,
            callData: callData,
            callGasLimit: callGasLimit,
            verificationGasLimit: verificationGasLimit,
            preVerificationGas: preVerificationGas,
            maxFeePerGas: maxFeePerGas,
            maxPriorityFeePerGas: maxPriorityFeePerGas,
            paymasterAndData: data,
            signature: signature
        )
    }
}

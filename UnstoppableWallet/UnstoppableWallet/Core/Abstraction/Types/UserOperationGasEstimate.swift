import BigInt
import Foundation

public struct UserOperationGasEstimate: Equatable, Hashable {
    public let callGasLimit: BigUInt
    public let verificationGasLimit: BigUInt
    public let preVerificationGas: BigUInt

    public init(callGasLimit: BigUInt, verificationGasLimit: BigUInt, preVerificationGas: BigUInt) {
        self.callGasLimit = callGasLimit
        self.verificationGasLimit = verificationGasLimit
        self.preVerificationGas = preVerificationGas
    }
}

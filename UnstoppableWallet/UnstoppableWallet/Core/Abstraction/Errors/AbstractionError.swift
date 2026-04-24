import Foundation

public enum AbstractionError: Error {
    case invalidUserOperation
    case invalidSignature
    case nativeNotSupported
    case unsupportedToken(tokenAddress: String)
    case notEnoughTokenForGas(symbol: String, required: String, available: String)
    case bundlerRejected(code: Int, message: String)
    case paymasterRejected(message: String)
    case userOpHashMismatch
    case entryPointNotSupported
    case invalidContractAddress
    case accountNotDeployed
    case unsupportedChain(chainId: Int)
}

extension AbstractionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidUserOperation:
            return "Invalid UserOperation format"
        case .invalidSignature:
            return "Invalid signature"
        case .nativeNotSupported:
            return "Native token operations are not supported in this wallet"
        case let .unsupportedToken(address):
            return "Unsupported token: \(address)"
        case let .notEnoughTokenForGas(symbol, required, available):
            return "Not enough \(symbol) for gas. Required: \(required), available: \(available)"
        case let .bundlerRejected(code, message):
            return "Bundler rejected UserOp (\(code)): \(message)"
        case let .paymasterRejected(message):
            return "Paymaster rejected UserOp: \(message)"
        case .userOpHashMismatch:
            return "UserOperation hash mismatch"
        case .entryPointNotSupported:
            return "EntryPoint version not supported"
        case .invalidContractAddress:
            return "Invalid contract address"
        case .accountNotDeployed:
            return "Smart account not deployed"
        case let .unsupportedChain(chainId):
            return "Chain \(chainId) not supported"
        }
    }
}

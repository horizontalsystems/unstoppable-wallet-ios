import Foundation
import HsToolKit
import MarketKit

protocol IContractAddressValidator {
    func canCheck(blockchainType: BlockchainType) -> Bool
    func supports(token: Token) -> Bool
    func isClear(address: Address, coinUid: String, blockchainType: BlockchainType, contractAddress: String) async throws -> Bool
}

class ContractAddressValidatorChain: IAddressSecurityChecker {
    private var validators: [IContractAddressValidator] = []

    func append(validator: IContractAddressValidator) {
        validators.append(validator)
    }

    func canCheck(blockchainType: BlockchainType) -> Bool {
        validators.contains(where: { $0.canCheck(blockchainType: blockchainType) })
    }

    func supports(token: Token) -> Bool {
        for validator in validators {
            if validator.supports(token: token) {
                return true
            }
        }
        return false
    }

    func isClear(address: Address, coinUid: String, blockchainType: BlockchainType, contractAddress: String) async throws -> Bool {
        var lastError: Error?
        var result: Bool?
        for validator in validators {
            do {
                let isClear = try await validator.isClear(address: address, coinUid: coinUid, blockchainType: blockchainType, contractAddress: contractAddress)
                if let previous = result {
                    result = previous && isClear
                } else {
                    result = isClear
                }
            } catch {
                lastError = error
            }
        }

        if let result {
            return result
        }

        throw lastError ?? ContractAddressValidatorChain.CheckError.noValidators
    }

    func isClear(address: Address, token: Token) async throws -> Bool {
        guard case let .eip20(contractAddress) = token.type else {
            throw ContractAddressValidatorChain.CheckError.invalidTokenType
        }

        return try await isClear(address: address, coinUid: token.coin.uid, blockchainType: token.blockchainType, contractAddress: contractAddress)
    }
}

extension ContractAddressValidatorChain {
    enum Method {
        case isBlackListed
        case isBlacklisted
        case isFrozen
    }

    enum CheckError: Error {
        case invalidTokenType
        case invalidAddress
        case invalidContractAddress
        case noSyncSource
        case noMethod
        case noValidators
    }
}

import EvmKit
import Foundation
import HsToolKit
import MarketKit

class Eip20AddressValidator {
    private let evmSyncSourceManager = Core.shared.evmSyncSourceManager
    private let networkManager = Core.shared.networkManager

    private static func method(coinUid: String, blockchainType: BlockchainType) -> Method? {
        switch coinUid {
        case "tether":
            switch blockchainType {
            case .ethereum: return .isBlackListed
            default: return nil
            }
        case "usd-coin":
            switch blockchainType {
            case .ethereum, .optimism, .avalanche, .arbitrumOne, .polygon, .zkSync, .base: return .isBlacklisted
            default: return nil
            }
        case "paypal-usd":
            switch blockchainType {
            case .ethereum: return .isFrozen
            default: return nil
            }
        default: return nil
        }
    }
}

extension Eip20AddressValidator {
    static func supports(token: Token) -> Bool {
        method(coinUid: token.coin.uid, blockchainType: token.blockchainType) != nil
    }

    func isClear(address: Address, coinUid: String, blockchainType: BlockchainType, contractAddress: String) async throws -> Bool {
        guard let evmAddress = try? EvmKit.Address(hex: address.raw) else {
            throw CheckError.invalidAddress
        }

        guard let contractAddress = try? EvmKit.Address(hex: contractAddress) else {
            throw CheckError.invalidContractAddress
        }

        guard let syncSource = evmSyncSourceManager.defaultSyncSources(blockchainType: blockchainType).first else {
            throw CheckError.noSyncSource
        }

        guard let method = Self.method(coinUid: coinUid, blockchainType: blockchainType) else {
            throw CheckError.noMethod
        }

        let responseData = try await EvmKit.Kit.call(
            networkManager: networkManager,
            rpcSource: syncSource.rpcSource,
            contractAddress: contractAddress,
            data: method.contractMethod(address: evmAddress).encodedABI(),
            defaultBlockParameter: .latest
        )

        return !responseData.contains(0x01)
    }
}

extension Eip20AddressValidator: IAddressSecurityChecker {
    func isClear(address: Address, token: Token) async throws -> Bool {
        guard case let .eip20(contractAddress) = token.type else {
            throw CheckError.invalidTokenType
        }

        return try await isClear(address: address, coinUid: token.coin.uid, blockchainType: token.blockchainType, contractAddress: contractAddress)
    }
}

extension Eip20AddressValidator {
    enum CheckError: Error {
        case invalidTokenType
        case invalidAddress
        case invalidContractAddress
        case noSyncSource
        case noMethod
    }

    enum Method {
        case isBlackListed
        case isBlacklisted
        case isFrozen

        func contractMethod(address: EvmKit.Address) -> ContractMethod {
            switch self {
            case .isBlackListed: return IsBlackListedMethod(address: address)
            case .isBlacklisted: return IsBlacklistedMethod(address: address)
            case .isFrozen: return IsFrozenMethod(address: address)
            }
        }
    }
}

extension Eip20AddressValidator {
    class IsBlackListedMethod: ContractMethod {
        private let address: EvmKit.Address

        init(address: EvmKit.Address) {
            self.address = address
        }

        override var methodSignature: String {
            "isBlackListed(address)"
        }

        override var arguments: [Any] {
            [address]
        }
    }

    class IsBlacklistedMethod: ContractMethod {
        private let address: EvmKit.Address

        init(address: EvmKit.Address) {
            self.address = address
        }

        override var methodSignature: String {
            "isBlacklisted(address)"
        }

        override var arguments: [Any] {
            [address]
        }
    }

    class IsFrozenMethod: ContractMethod {
        private let address: EvmKit.Address

        init(address: EvmKit.Address) {
            self.address = address
        }

        override var methodSignature: String {
            "isFrozen(address)"
        }

        override var arguments: [Any] {
            [address]
        }
    }
}

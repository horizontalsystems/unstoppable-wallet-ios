import EvmKit
import Foundation
import HsToolKit
import MarketKit

class Eip20AddressValidator {
    private let evmSyncSourceManager: EvmSyncSourceManager
    private let networkManager: NetworkManager

    init(evmSyncSourceManager: EvmSyncSourceManager, networkManager: NetworkManager) {
        self.evmSyncSourceManager = evmSyncSourceManager
        self.networkManager = networkManager
    }

    private func method(coinUid: String, blockchainType: BlockchainType) -> ContractAddressValidatorChain.Method? {
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

    private func contractMethod(address: EvmKit.Address, method: ContractAddressValidatorChain.Method) -> ContractMethod {
        switch method {
        case .isBlackListed: return IsBlackListedMethod(address: address)
        case .isBlacklisted: return IsBlacklistedMethod(address: address)
        case .isFrozen: return IsFrozenMethod(address: address)
        }
    }
}

extension Eip20AddressValidator: IContractAddressValidator {
    func canCheck(blockchainType: BlockchainType) -> Bool {
        EvmBlockchainManager.blockchainTypes.contains(blockchainType)
    }

    func supports(token: Token) -> Bool {
        method(coinUid: token.coin.uid, blockchainType: token.blockchainType) != nil
    }

    func isClear(address: Address, coinUid: String, blockchainType: BlockchainType, contractAddress: String) async throws -> Bool {
        guard let evmAddress = try? EvmKit.Address(hex: address.raw) else {
            throw ContractAddressValidatorChain.CheckError.invalidAddress
        }

        guard let contractAddress = try? EvmKit.Address(hex: contractAddress) else {
            throw ContractAddressValidatorChain.CheckError.invalidContractAddress
        }

        guard let syncSource = evmSyncSourceManager.defaultSyncSources(blockchainType: blockchainType).first else {
            throw ContractAddressValidatorChain.CheckError.noSyncSource
        }

        guard let method = method(coinUid: coinUid, blockchainType: blockchainType) else {
            throw ContractAddressValidatorChain.CheckError.noMethod
        }

        let responseData = try await EvmKit.Kit.call(
            networkManager: networkManager,
            rpcSource: syncSource.rpcSource,
            contractAddress: contractAddress,
            data: contractMethod(address: evmAddress, method: method).encodedABI(),
            defaultBlockParameter: .latest
        )

        return !responseData.contains(0x01)
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

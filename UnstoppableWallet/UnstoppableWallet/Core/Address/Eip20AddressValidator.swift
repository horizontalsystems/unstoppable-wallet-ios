import EvmKit
import HsToolKit
import MarketKit

class Eip20AddressValidator {
    private let evmSyncSourceManager: EvmSyncSourceManager

    init() {
        evmSyncSourceManager = App.shared.evmSyncSourceManager
    }

    static func method(address: Address, contractAddress: EvmKit.Address) -> ContractMethod? {
        guard let evmAddress = try? EvmKit.Address(hex: address.raw) else {
            return nil
        }

        if Eip20AddressValidator.IsBlacklistedMethod.contractAddresses.contains(contractAddress.eip55) {
            return IsBlacklistedMethod(address: evmAddress)
        }

        return nil
    }

    static func supports(token: Token) -> Bool {
        guard case let .eip20(addressString) = token.type,
              let contractAddress = try? EvmKit.Address(hex: addressString)
        else {
            return false
        }

        return method(address: Address(raw: ""), contractAddress: contractAddress) != nil
    }
}

extension Eip20AddressValidator: IAddressSecurityChecker {
    func check(address: Address, token: Token) async throws -> Bool {
        guard case let .eip20(addressString) = token.type,
              let contractAddress = try? EvmKit.Address(hex: addressString),
              let syncSource = evmSyncSourceManager.defaultSyncSources(blockchainType: token.blockchainType).first,
              let method = Self.method(address: address, contractAddress: contractAddress)
        else {
            return false
        }

        let networkManager = NetworkManager(logger: App.shared.logger)
        let responseData = try await EvmKit.Kit.call(
            networkManager: networkManager,
            rpcSource: syncSource.rpcSource,
            contractAddress: contractAddress,
            data: method.encodedABI(),
            defaultBlockParameter: .latest
        )
        return responseData.contains(0x01)
    }
}

extension Eip20AddressValidator {
    class IsBlacklistedMethod: ContractMethod {
        static let contractAddresses = [
            "0xdAC17F958D2ee523a2206206994597C13D831ec7",
        ]

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
}

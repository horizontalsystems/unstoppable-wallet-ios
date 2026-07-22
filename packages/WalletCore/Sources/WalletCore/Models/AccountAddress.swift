import EvmKit
import MarketKit
import ThorChainKit
import TronKit

public enum AccountAddress {
    private static var providers: [IAccountAddressProvider] = [AccountAddressProvider()]

    public static func register(_ provider: IAccountAddressProvider) {
        providers.insert(provider, at: 0)
    }

    static func evmAddress(account: Account, blockchainType: BlockchainType) throws -> EvmKit.Address {
        for provider in providers {
            if let address = try provider.evmAddress(account: account, blockchainType: blockchainType) {
                return address
            }
        }

        throw AdapterError.unsupportedAccount
    }

    static func tronAddress(account: Account) throws -> TronKit.Address {
        for provider in providers {
            if let address = try provider.tronAddress(account: account) {
                return address
            }
        }

        throw AdapterError.unsupportedAccount
    }

    static func thorChainAddress(account: Account) throws -> ThorChainKit.Address {
        for provider in providers {
            if let address = try provider.thorChainAddress(account: account) {
                return address
            }
        }

        throw AdapterError.unsupportedAccount
    }
}

public protocol IAccountAddressProvider {
    func evmAddress(account: Account, blockchainType: BlockchainType) throws -> EvmKit.Address?
    func tronAddress(account: Account) throws -> TronKit.Address?
}

public extension IAccountAddressProvider {
    func thorChainAddress(account: Account) throws -> ThorChainKit.Address? {
        nil
    }
}

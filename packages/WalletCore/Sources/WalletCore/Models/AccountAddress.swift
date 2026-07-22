import EvmKit
import HdWalletKit
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
        guard let seed = account.type.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        let wallet = HDWallet(
            seed: seed,
            coinType: ThorChainKit.Network.mainnet.coinType,
            xPrivKey: HDExtendedKeyVersion.xprv.rawValue,
            purpose: .bip44,
            curve: .secp256k1
        )
        let path = ThorChainKit.DerivationPath.defaultAccount.rawValue
        let compressedPublicKey = try wallet
            .privateKey(path: path)
            .publicKey(curve: .secp256k1)
            .raw

        return try ThorChainKit.AccountAddressFactory.address(
            compressedPublicKey: compressedPublicKey,
            network: .mainnet
        )
    }
}

public protocol IAccountAddressProvider {
    func evmAddress(account: Account, blockchainType: BlockchainType) throws -> EvmKit.Address?
    func tronAddress(account: Account) throws -> TronKit.Address?
}

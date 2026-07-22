import EvmKit
import MarketKit
import ThorChainKit
import TronKit

enum AccountAddress {
    static func evmAddress(account: Account, blockchainType: BlockchainType) throws -> EvmKit.Address {
        switch account.type {
        case .mnemonic:
            guard let seed = account.type.mnemonicSeed else {
                throw AdapterError.unsupportedAccount
            }
            let chain = try Core.shared.evmBlockchainManager.chain(blockchainType: blockchainType)
            return try EvmKit.Signer.address(seed: seed, chain: chain)

        case let .evmPrivateKey(data):
            return EvmKit.Signer.address(privateKey: data)

        case let .evmAddress(address):
            return address

        case .passkeyOwned:
            guard let profile = try Core.shared.smartAccountManager.profile(accountId: account.id) else {
                throw AdapterError.unsupportedAccount
            }
            return try profile.address(blockchainType: blockchainType)

        default:
            throw AdapterError.unsupportedAccount
        }
    }

    static func tronAddress(account: Account) throws -> TronKit.Address {
        switch account.type {
        case .mnemonic:
            guard let seed = account.type.mnemonicSeed else {
                throw AdapterError.unsupportedAccount
            }
            return try TronKit.Signer.address(seed: seed)

        case let .trcPrivateKey(data):
            return try TronKit.Signer.address(privateKey: data)

        case let .tronAddress(address):
            return address

        case .passkeyOwned:
            // TODO: make this async and create the GasFree profile on demand when missing
            // (e.g. after account restore where the profile didn't carry over). For now
            // we throw; the profile is only ever populated by CreateSmartAccountService.
            guard let profile = try Core.shared.smartAccountManager.gasFreeProfile(accountId: account.id) else {
                throw AdapterError.unsupportedAccount
            }
            return profile.gasFreeAddress

        default:
            throw AdapterError.unsupportedAccount
        }
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

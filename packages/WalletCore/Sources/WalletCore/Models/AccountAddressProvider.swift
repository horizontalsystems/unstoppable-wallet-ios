import EvmKit
import HdWalletKit
import MarketKit
import ThorChainKit
import TronKit

class AccountAddressProvider: IAccountAddressProvider {
    func evmAddress(account: Account, blockchainType: BlockchainType) throws -> EvmKit.Address? {
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

        default:
            return nil
        }
    }

    func tronAddress(account: Account) throws -> TronKit.Address? {
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

        default:
            return nil
        }
    }

    func thorChainAddress(account: Account) throws -> ThorChainKit.Address? {
        guard let seed = account.type.mnemonicSeed else {
            return nil
        }

        let wallet = HDWallet(
            seed: seed,
            coinType: ThorChainKit.Network.mainnet.coinType,
            xPrivKey: HDExtendedKeyVersion.xprv.rawValue,
            purpose: .bip44,
            curve: .secp256k1
        )
        let compressedPublicKey = try wallet
            .privateKey(path: ThorChainKit.DerivationPath.defaultAccount.rawValue)
            .publicKey(curve: .secp256k1)
            .raw

        return try ThorChainKit.AccountAddressFactory.address(
            compressedPublicKey: compressedPublicKey,
            network: .mainnet
        )
    }
}

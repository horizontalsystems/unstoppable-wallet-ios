import EvmKit

class WalletConnectManager {
    private let accountManager: AccountManager
    private let evmBlockchainManager: EvmBlockchainManager

    init(accountManager: AccountManager, evmBlockchainManager: EvmBlockchainManager) {
        self.accountManager = accountManager
        self.evmBlockchainManager = evmBlockchainManager
    }

    var activeAccount: Account? {
        accountManager.activeAccount
    }

    static func evmAddress(account: Account, chain: Chain) throws -> EvmKit.Address {
        if let mnemonicSeed = account.type.mnemonicSeed {
            return try Signer.address(seed: mnemonicSeed, chain: chain)
        }
        if case let .evmPrivateKey(data) = account.type {
            return Signer.address(privateKey: data)
        }
        if case let .evmAddress(address) = account.type {
            return address
        }
        throw AdapterError.unsupportedAccount
    }

    func evmKitWrapper(chainId: Int, account: Account) -> EvmKitWrapper? {
        guard let blockchainType = evmBlockchainManager.blockchain(chainId: chainId)?.type else {
            return nil
        }

        return try? evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper(account: account, blockchainType: blockchainType)
    }

}

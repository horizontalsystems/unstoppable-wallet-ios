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

    func evmKitWrapper(chainId: Int, account: Account) -> EvmKitWrapper? {
        guard let blockchainType = evmBlockchainManager.blockchain(chainId: chainId)?.type else {
            return nil
        }

        return try? evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper(account: account, blockchainType: blockchainType)
    }

}

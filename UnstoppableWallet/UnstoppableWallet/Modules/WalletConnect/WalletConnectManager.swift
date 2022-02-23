import EthereumKit

class WalletConnectManager {
    private let accountManager: IAccountManager
    private let evmBlockchainManager: EvmBlockchainManager

    init(accountManager: IAccountManager, evmBlockchainManager: EvmBlockchainManager) {
        self.accountManager = accountManager
        self.evmBlockchainManager = evmBlockchainManager
    }

    var activeAccount: Account? {
        accountManager.activeAccount
    }

    func evmKitWrapper(chainId: Int, account: Account) -> EvmKitWrapper? {
        guard let blockchain = evmBlockchainManager.blockchain(chainId: chainId) else {
            return nil
        }

        return try? evmBlockchainManager.evmKitManager(blockchain: blockchain).evmKitWrapper(account: account, blockchain: blockchain)
    }

}

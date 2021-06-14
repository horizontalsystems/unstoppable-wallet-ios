import EthereumKit

class WalletConnectManager {
    private let accountManager: IAccountManager
    private let ethereumKitManager: EvmKitManager
    private let binanceSmartChainKitManager: EvmKitManager

    init(accountManager: IAccountManager, ethereumKitManager: EvmKitManager, binanceSmartChainKitManager: EvmKitManager) {
        self.accountManager = accountManager
        self.ethereumKitManager = ethereumKitManager
        self.binanceSmartChainKitManager = binanceSmartChainKitManager
    }

    var activeAccount: Account? {
        accountManager.activeAccount
    }

    func evmKit(chainId: Int, account: Account) -> EthereumKit.Kit? {
        if chainId == 1 {
            return try? ethereumKitManager.evmKit(account: account)
        }

        if chainId == 56 {
            return try? binanceSmartChainKitManager.evmKit(account: account)
        }

        return nil
    }

}

import EthereumKit

class WalletConnectManager {
    private let accountManager: IAccountManager
    private let ethereumKitManager: EthereumKitManager
    private let binanceSmartChainKitManager: BinanceSmartChainKitManager

    init(accountManager: IAccountManager, ethereumKitManager: EthereumKitManager, binanceSmartChainKitManager: BinanceSmartChainKitManager) {
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

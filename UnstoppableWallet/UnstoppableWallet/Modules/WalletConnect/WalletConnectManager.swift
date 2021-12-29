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

    func evmKitWrapper(chainId: Int, account: Account) -> EvmKitWrapper? {
        if let ethereumKitWrapper = try? ethereumKitManager.evmKitWrapper(account: account), ethereumKitWrapper.evmKit.networkType.chainId == chainId {
            return ethereumKitWrapper
        }

        if let binanceSmartChainKitWrapper = try? binanceSmartChainKitManager.evmKitWrapper(account: account), binanceSmartChainKitWrapper.evmKit.networkType.chainId == chainId {
            return binanceSmartChainKitWrapper
        }

        return nil
    }

}

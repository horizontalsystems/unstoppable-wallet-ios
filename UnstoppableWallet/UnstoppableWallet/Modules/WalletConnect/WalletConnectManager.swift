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
        if let ethereumKit = try? ethereumKitManager.evmKit(account: account), ethereumKit.networkType.chainId == chainId {
            return ethereumKit
        }

        if let binanceSmartChainKit = try? binanceSmartChainKitManager.evmKit(account: account), binanceSmartChainKit.networkType.chainId == chainId {
            return binanceSmartChainKit
        }

        return nil
    }

}

import EthereumKit

class WalletConnectManager {
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager
    private let ethereumKitManager: EthereumKitManager
    private let binanceSmartChainKitManager: BinanceSmartChainKitManager

    init(predefinedAccountTypeManager: IPredefinedAccountTypeManager, ethereumKitManager: EthereumKitManager, binanceSmartChainKitManager: BinanceSmartChainKitManager) {
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
        self.ethereumKitManager = ethereumKitManager
        self.binanceSmartChainKitManager = binanceSmartChainKitManager
    }

    // todo: this method should not accept chainId after implementing multi-account feature
    func currentAccount(chainId: Int) -> Account? {
        if chainId == 1 {
            return predefinedAccountTypeManager.account(predefinedAccountType: .standard)
        }

        if chainId == 56 {
            return predefinedAccountTypeManager.account(predefinedAccountType: .binance)
        }

        return nil
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

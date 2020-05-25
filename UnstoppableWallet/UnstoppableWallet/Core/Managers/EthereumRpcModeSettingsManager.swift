class EthereumRpcModeSettingsManager {
    private let ethereumKitManager: EthereumKitManager
    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let localStorage: ILocalStorage

    init (ethereumKitManager: EthereumKitManager, walletManager: IWalletManager, adapterManager: IAdapterManager, localStorage: ILocalStorage) {
        self.ethereumKitManager = ethereumKitManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.localStorage = localStorage
    }

}

extension EthereumRpcModeSettingsManager: IEthereumRpcModeSettingsManager {

    var rpcMode: EthereumRpcMode {
        localStorage.ethereumRpcMode ?? .infura
    }

    func save(rpcMode: EthereumRpcMode) {
        localStorage.ethereumRpcMode = rpcMode

        let walletsForUpdate = walletManager.wallets.filter { wallet in
            switch wallet.coin.type {
            case .ethereum, .erc20: return true
            default: return false
            }
        }

        if !walletsForUpdate.isEmpty {
            ethereumKitManager.ethereumKit = nil
            adapterManager.refreshAdapters(wallets: walletsForUpdate)
        }
    }

}

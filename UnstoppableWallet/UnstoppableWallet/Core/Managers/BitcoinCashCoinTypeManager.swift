class BitcoinCashCoinTypeManager {
    private let defaultCoinType: BitcoinCashCoinType = .type145

    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let storage: IBlockchainSettingsStorage

    init (walletManager: IWalletManager, adapterManager: IAdapterManager, storage: IBlockchainSettingsStorage) {
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.storage = storage
    }

}

extension BitcoinCashCoinTypeManager {

    var bitcoinCashCoinType: BitcoinCashCoinType {
        storage.bitcoinCashCoinType ?? defaultCoinType
    }

    var hasActiveSetting: Bool {
        walletManager.wallets.contains { $0.coin.type == .bitcoinCash }
    }

    func save(bitcoinCashCoinType: BitcoinCashCoinType) {
        storage.bitcoinCashCoinType = bitcoinCashCoinType

        let walletsForUpdate = walletManager.wallets.filter { $0.coin.type == .bitcoinCash }

        if !walletsForUpdate.isEmpty {
            adapterManager.refreshAdapters(wallets: walletsForUpdate)
        }
    }

    func reset() {
        storage.bitcoinCashCoinType = nil
    }

}

class BlockchainSettingsInteractor {
    private var blockchainSettingsManager: IBlockchainSettingsManager
    private let walletManager: IWalletManager

    init(coinSettingsManager: IBlockchainSettingsManager, walletManager: IWalletManager) {
        self.blockchainSettingsManager = coinSettingsManager
        self.walletManager = walletManager
    }

}

extension BlockchainSettingsInteractor: IBlockchainSettingsInteractor {

    func settings(coinType: CoinType) -> BlockchainSetting? {
        blockchainSettingsManager.settings(coinType: coinType)
    }

    func walletsForUpdate(coinType: CoinType) -> [Wallet] {
        walletManager.wallets.filter { $0.coin.type == coinType }
    }

}

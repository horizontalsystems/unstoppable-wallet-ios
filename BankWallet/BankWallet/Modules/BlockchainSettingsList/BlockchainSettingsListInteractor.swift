class BlockchainSettingsListInteractor {
    private let blockchainSettingsManager: ICoinSettingsManager
    private let walletManager: IWalletManager

    init(blockchainSettingsManager: ICoinSettingsManager, walletManager: IWalletManager) {
        self.blockchainSettingsManager = blockchainSettingsManager
        self.walletManager = walletManager
    }

}

extension BlockchainSettingsListInteractor: IBlockchainSettingsListInteractor {

    var blockchainSettings: [BlockchainSetting] {
        blockchainSettingsManager.allSettings
    }

    var settableCoins: [Coin] {
        blockchainSettingsManager.settableCoins
    }

    func save(settings: [BlockchainSetting]) {
        blockchainSettingsManager.save(settings: settings)
    }

    func update(wallets: [Wallet]) {
        walletManager.save(wallets: wallets)
    }

}
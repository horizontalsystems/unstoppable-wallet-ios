class BlockchainSettingsInteractor {
    private var coinSettingsManager: ICoinSettingsManager
    private let walletManager: IWalletManager

    init(coinSettingsManager: ICoinSettingsManager, walletManager: IWalletManager) {
        self.coinSettingsManager = coinSettingsManager
        self.walletManager = walletManager
    }

}

extension BlockchainSettingsInteractor: IBlockchainSettingsInteractor {

    var bitcoinDerivation: MnemonicDerivation {
        get {
            coinSettingsManager.bitcoinDerivation
        }
        set {
            coinSettingsManager.bitcoinDerivation = newValue
        }
    }

    var syncMode: SyncMode {
        get {
            coinSettingsManager.syncMode
        }
        set {
            coinSettingsManager.syncMode = newValue
        }
    }

    var walletsForDerivationUpdate: [Wallet] {
        walletManager.wallets.filter { $0.coinSettings[CoinSetting.derivation] != nil }
    }

    var walletsForSyncModeUpdate: [Wallet] {
        walletManager.wallets.filter { $0.coinSettings[CoinSetting.syncMode] != nil }
    }

    func update(derivation: MnemonicDerivation, in wallets: [Wallet]) {
        walletManager.update(derivation: derivation, in: wallets)
    }

    func update(syncMode: SyncMode, in wallets: [Wallet]) {
        walletManager.update(syncMode: syncMode, in: wallets)
    }

}

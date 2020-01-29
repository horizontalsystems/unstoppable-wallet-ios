class BlockchainSettingsInteractor {
    private var coinSettingsManager: ICoinSettingsManager

    init(coinSettingsManager: ICoinSettingsManager) {
        self.coinSettingsManager = coinSettingsManager
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

}

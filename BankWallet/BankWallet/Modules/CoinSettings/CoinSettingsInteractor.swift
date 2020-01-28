class CoinSettingsInteractor {
    private var coinSettingsManager: ICoinSettingsManager

    init(coinSettingsManager: ICoinSettingsManager) {
        self.coinSettingsManager = coinSettingsManager
    }

}

extension CoinSettingsInteractor: ICoinSettingsInteractor {

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

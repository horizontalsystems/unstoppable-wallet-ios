protocol ICoinSettingsManager {
    var bitcoinDerivation: MnemonicDerivation { get set }
    var syncMode: SyncMode { get set }

    func coinSettingsForCreate(coinType: CoinType) -> CoinSettings
    func coinSettings(coinType: CoinType) -> CoinSettings
}

class CoinSettingsManager: ICoinSettingsManager {
    private let defaultDerivation: MnemonicDerivation = .bip49
    private let defaultSyncMode: SyncMode = .fast

    let localStorage: ILocalStorage

    init (localStorage: ILocalStorage) {
        self.localStorage = localStorage
    }

    var bitcoinDerivation: MnemonicDerivation {
        get {
            localStorage.bitcoinDerivation ?? defaultDerivation
        }
        set {
            localStorage.bitcoinDerivation = newValue
        }
    }
    var syncMode: SyncMode {
        get {
            localStorage.syncMode ?? defaultSyncMode
        }
        set {
            localStorage.syncMode = newValue
        }
    }

    func coinSettingsForCreate(coinType: CoinType) -> CoinSettings {
        coinType.settings.reduce (CoinSettings()) { coinSettings, value in
            var coinSettings = coinSettings
            switch value {
            case .derivation: coinSettings[CoinSetting.derivation] = defaultDerivation
            case .syncMode: coinSettings[CoinSetting.syncMode] = SyncMode.new
            }
            return coinSettings
        }
    }

    func coinSettings(coinType: CoinType) -> CoinSettings {
        var coinSettings = CoinSettings()

        for setting in coinType.settings {
            switch setting {
            case .derivation:
                coinSettings[.derivation] = bitcoinDerivation
            case .syncMode:
                coinSettings[.syncMode] = syncMode
            }
        }

        return coinSettings
    }

}

protocol ICoinSettingsManager {
    func coinSettingsToRequest(coin: Coin, accountOrigin: AccountOrigin) -> CoinSettings
    func coinSettingsToSave(coin: Coin, accountOrigin: AccountOrigin, requestedCoinSettings: CoinSettings) -> CoinSettings
}

class CoinSettingsManager: ICoinSettingsManager {
    private let defaultDerivation: MnemonicDerivation = .bip49
    private let defaultSyncMode: SyncMode = .fast

    func coinSettingsToRequest(coin: Coin, accountOrigin: AccountOrigin) -> CoinSettings {
        var coinSettings = CoinSettings()

        for setting in coin.type.settings {
            switch setting {
            case .derivation:
                coinSettings[.derivation] = defaultDerivation
            case .syncMode:
                if accountOrigin == .restored {
                    coinSettings[.syncMode] = defaultSyncMode
                }
            }
        }

        return coinSettings
    }

    func coinSettingsToSave(coin: Coin, accountOrigin: AccountOrigin, requestedCoinSettings: CoinSettings) -> CoinSettings {
        var coinSettings = requestedCoinSettings

        for setting in coin.type.settings {
            switch setting {
            case .syncMode:
                if accountOrigin == .created {
                    coinSettings[.syncMode] = SyncMode.new
                }
            default: ()
            }
        }

        return coinSettings
    }

}

protocol ICoinSettingsView: class {
    func set(coinTitle: String)
    func set(restoreUrl: String)
    func set(derivation: MnemonicDerivation)
    func set(syncMode: SyncMode)
}

protocol ICoinSettingsViewDelegate {
    func onLoad()
    func onSelect(derivation: MnemonicDerivation)
    func onSelect(syncMode: SyncMode)
    func onTapEnableButton()
    func onTapCancelButton()
    func onTapLink()
}

protocol ICoinSettingsRouter {
    func notifySelectedAndClose(coinSettings: CoinSettings, coin: Coin)
    func notifyCancelledAndClose()
    func open(url: String)
}

protocol ICoinSettingsDelegate: class {
    func onSelect(coinSettings: CoinSettings, coin: Coin)
    func onCancelSelectingCoinSettings()
}

class CoinSettingsModule {

    enum Mode {
        case create
        case restore
    }

}

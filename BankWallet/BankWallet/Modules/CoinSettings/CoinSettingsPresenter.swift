class CoinSettingsPresenter {
    weak var view: ICoinSettingsView?

    private let coin: Coin
    private var coinSettings: CoinSettings
    private let router: ICoinSettingsRouter

    init(coin: Coin, coinSettings: CoinSettings, router: ICoinSettingsRouter) {
        self.coin = coin
        self.coinSettings = coinSettings
        self.router = router
    }

}

extension CoinSettingsPresenter: ICoinSettingsViewDelegate {

    func onLoad() {
        view?.set(coinTitle: coin.title)
        view?.set(restoreUrl: coin.type.restoreUrl)

        for (setting, value) in coinSettings {
            switch setting {
            case .derivation:
                if let derivation = value as? MnemonicDerivation {
                    view?.set(derivation: derivation)
                }
            case .syncMode:
                if let syncMode = value as? SyncMode {
                    view?.set(syncMode: syncMode)
                }
            }
        }
    }

    func onSelect(derivation: MnemonicDerivation) {
        coinSettings[.derivation] = derivation
    }

    func onSelect(syncMode: SyncMode) {
        coinSettings[.syncMode] = syncMode
    }

    func onTapEnableButton() {
        router.notifySelectedAndClose(coinSettings: coinSettings, coin: coin)
    }

    func onTapCancelButton() {
        router.notifyCancelledAndClose()
    }

    func onTapLink() {
        router.open(url: coin.type.restoreUrl)
    }

}

class BlockchainSettingsPresenter {
    weak var view: IBlockchainSettingsView?

    private let router: IBlockchainSettingsRouter
    private let interactor: IBlockchainSettingsInteractor
    private let updateDelegate: IBlockchainSettingsUpdateDelegate?

    private let factory = BlockchainSettingsFactory()

    private let coin: Coin
    private var settings: BlockchainSetting

    init(router: IBlockchainSettingsRouter, interactor: IBlockchainSettingsInteractor, coin: Coin, settings: BlockchainSetting, updateDelegate: IBlockchainSettingsUpdateDelegate) {
        self.router = router
        self.interactor = interactor
        self.updateDelegate = updateDelegate

        self.coin = coin
        self.settings = settings
    }

    private func updateUI() {
        view?.set(settings: factory.settings(coinType: coin.type, originalSettings: settings))
    }

}

extension BlockchainSettingsPresenter: IBlockchainSettingsViewDelegate {

    func onLoad() {
        view?.set(blockchainName: coin.title)
        updateUI()
    }

    func onSelect(derivation: MnemonicDerivation) {
        if settings.derivation != derivation, !interactor.walletsForUpdate(coinType: coin.type).isEmpty {
            view?.showChangeAlert(derivation: derivation)
        } else {
            settings.derivation = derivation

            updateDelegate?.onSelect(settings: settings, wallets: [])

            updateUI()
        }
    }

    func onSelect(syncMode: SyncMode) {
        if settings.syncMode != syncMode, !interactor.walletsForUpdate(coinType: coin.type).isEmpty {
            view?.showChangeAlert(syncMode: syncMode)
        } else {
            settings.syncMode = syncMode

            updateDelegate?.onSelect(settings: settings, wallets: [])

            updateUI()
        }
    }

    func proceedChange(derivation: MnemonicDerivation) {
        settings.derivation = derivation
        updateUI()

        updateDelegate?.onSelect(settings: settings, wallets: interactor.walletsForUpdate(coinType: coin.type))
    }

    func proceedChange(syncMode: SyncMode) {
        settings.syncMode = syncMode
        updateUI()

        updateDelegate?.onSelect(settings: settings, wallets: interactor.walletsForUpdate(coinType: coin.type))
    }

}

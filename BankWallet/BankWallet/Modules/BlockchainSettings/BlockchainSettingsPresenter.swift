class BlockchainSettingsPresenter {
    weak var view: IBlockchainSettingsView?

    private let proceedMode: RestoreRouter.ProceedMode
    private let router: IBlockchainSettingsRouter
    private let interactor: IBlockchainSettingsInteractor

    private let factory = DerivationSettingsViewItemFactory()

    private var allSettings: [MnemonicDerivation]
    private var coinsWithSettings: [Coin]

    private var selectedSettings: [Coin: MnemonicDerivation]
    private var selectedCoins: [Coin]

    private let canSave: Bool

    init(proceedMode: RestoreRouter.ProceedMode, router: IBlockchainSettingsRouter, interactor: IBlockchainSettingsInteractor, selectedCoins: [Coin], showOnlyCoin: Coin?, canSave: Bool) {
        self.proceedMode = proceedMode
        self.router = router
        self.interactor = interactor
        self.selectedCoins = selectedCoins
        self.canSave = canSave

        allSettings = MnemonicDerivation.allCases
        coinsWithSettings = interactor.allCoins.filter { coin in
            if let showOnlyCoin = showOnlyCoin, coin != showOnlyCoin {
                return false
            }
            return interactor.settings(coinType: coin.type) != nil
        }

        selectedSettings = coinsWithSettings.reduce([Coin: MnemonicDerivation]()) { dictionary, coin in
            var dictionary = dictionary
            dictionary[coin] = interactor.settings(coinType: coin.type)?.derivation
            return dictionary
        }
    }

    private func updateUI() {
        view?.set(viewItems: coinsWithSettings.compactMap { coin in
            guard let selectedSetting = selectedSettings[coin] else {
                return nil
            }

            return factory.sectionViewItem(coin: coin, selectedCoins: selectedCoins, selectedSetting: selectedSetting, allSettings: allSettings)
        })
    }

    private func createDerivationSettings() -> [DerivationSetting] {
        selectedSettings.map { coin, derivation in DerivationSetting(coinType: coin.type, derivation: derivation) }
    }

}

extension BlockchainSettingsPresenter: IBlockchainSettingsViewDelegate {

    func onLoad() {
        switch proceedMode {
        case .next:
            view?.showNextButton()
        case .restore:
            view?.showRestoreButton()
        case .done:
            view?.showDoneButton()
        case .none: ()
        }

        updateUI()
    }

    func onConfirm() {
        router.notifyConfirm(settings: createDerivationSettings())

        if proceedMode == .done {
            router.close()
        }
    }

    func onSelect(chainIndex: Int, settingIndex: Int) {
        let coin = coinsWithSettings[chainIndex]
        let derivation = allSettings[settingIndex]

        if selectedSettings[coin] != derivation, !interactor.walletsForUpdate(coinType: coin.type).isEmpty {
            view?.showChangeAlert(chainIndex: chainIndex, settingIndex: settingIndex, derivationText: derivation.rawValue)
        } else {
            selectedSettings[coin] = derivation

            if canSave {
                interactor.save(settings: createDerivationSettings())
            }

            updateUI()
        }

    }

    func proceedChange(chainIndex: Int, settingIndex: Int) {
        let coin = coinsWithSettings[chainIndex]
        let derivation = allSettings[settingIndex]
        selectedSettings[coin] = derivation

        if canSave {
            interactor.save(settings: createDerivationSettings())
            interactor.update(wallets: interactor.walletsForUpdate(coinType: coin.type))
        }

        updateUI()
    }

}

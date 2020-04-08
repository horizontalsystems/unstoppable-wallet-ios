class DerivationSettingsPresenter {
    weak var view: IDerivationSettingsView?

    private let router: IDerivationSettingsRouter
    private let interactor: IDerivationSettingsInteractor
    private let factory = DerivationSettingsViewItemFactory()

    private var items = [DerivationSettingItem]()

    init(router: IDerivationSettingsRouter, interactor: IDerivationSettingsInteractor) {
        self.router = router
        self.interactor = interactor
    }

    private func updateUI() {
        items = interactor.allActiveSettings.map { setting, wallets in
            DerivationSettingItem(firstCoin: wallets[0].coin, setting: setting)
        }

        let viewItems = items.map { factory.sectionViewItem(item: $0) }
        view?.set(viewItems: viewItems)
    }

}

extension DerivationSettingsPresenter: IDerivationSettingsViewDelegate {

    func onLoad() {
        updateUI()
    }

    func onSelect(chainIndex: Int, settingIndex: Int) {
        let item = items[chainIndex]
        let derivation = MnemonicDerivation.allCases[settingIndex]

        guard item.setting.derivation != derivation else {
            return
        }

        let newSetting = DerivationSetting(coinType: item.setting.coinType, derivation: derivation)
        view?.showChangeAlert(setting: newSetting, coinTitle: item.firstCoin.title)
    }

    func proceedChange(setting: DerivationSetting) {
        interactor.save(setting: setting)

        updateUI()
    }

}

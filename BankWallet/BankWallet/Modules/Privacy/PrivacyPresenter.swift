class PrivacyPresenter {
    weak var view: IPrivacyView?

    private let interactor: IPrivacyInteractor
    private let router: IPrivacyRouter
    private let factory = PrivacyViewItemFactory()

    private var syncItems = [PrivacySyncItem]()
    private let syncModes = [SyncMode.fast, SyncMode.slow]

    init(interactor: IPrivacyInteractor, router: IPrivacyRouter) {
        self.interactor = interactor
        self.router = router
    }

    private func updateSync() {
        view?.set(syncModeItems: factory.syncViewItems(items: syncItems))
    }

}

extension PrivacyPresenter: IPrivacyViewDelegate {

    func onLoad() {
        view?.set(sortingMode: "default")
        view?.set(connectionItems: [
            PrivacyViewItem(iconName: "ETH", title: "Ethereum", value: "Incubed", changable: true),
            PrivacyViewItem(iconName: "EOS", title: "EOS", value: "eos.greymass.com", changable: false),
            PrivacyViewItem(iconName: "BNB", title: "Binance", value: "dex.binance.com", changable: false)
        ])

        syncItems = interactor.syncSettings.compactMap {(setting, coins) in
            guard let coin = coins.first else {
                return nil
            }

            return PrivacySyncItem(coin: coin, setting: setting)
        }
        updateSync()

        view?.updateUI()
    }

    func onSelectSortMode() {

    }

    func onSelectConnection(index: Int) {

    }

    func onSelectSync(index: Int) {
        let currentSetting = syncItems[index]

        let coinName: String = currentSetting.coin.title
        let selectedSettingName: String = currentSetting.setting.syncMode.title
        let allSettings = syncModes.map { $0.title }

        view?.showSyncModeAlert(itemIndex: index, coinName: coinName, selected: selectedSettingName, all: allSettings)
    }

    func onSelectSyncSetting(itemIndex: Int, settingIndex: Int) {
        let oldSetting = syncItems[itemIndex].setting
        let newSetting = InitialSyncSetting(coinType: oldSetting.coinType, syncMode: syncModes[settingIndex])

        syncItems[itemIndex].setting = newSetting

        interactor.save(syncSetting: newSetting)

        updateSync()
        view?.updateUI()
    }

}

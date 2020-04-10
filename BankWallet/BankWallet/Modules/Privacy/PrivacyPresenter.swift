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

    private func updateSortMode() {
        view?.set(sortMode: interactor.sortMode.title)
    }

}

extension PrivacyPresenter: IPrivacyViewDelegate {

    func onLoad() {
        updateSortMode()

        view?.set(connectionItems: [
            PrivacyViewItem(iconName: "ETH", title: "Ethereum", value: "Incubed", changable: false),
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
        let selectedSettingName = interactor.sortMode.title
        let allSettings = TransactionDataSortMode.allCases.map { $0.title }

        view?.showSortModeAlert(selected: selectedSettingName, all: allSettings)
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

    func onSelectSortSetting(settingIndex: Int) {
        interactor.save(sortSetting: TransactionDataSortMode.allCases[settingIndex])

        updateSortMode()
        view?.updateUI()
    }

}

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

    private func updateSortMode() {
        view?.set(sortMode: interactor.sortMode.title)
    }

    private func updateConnection() {
        var connectionItems = [PrivacyViewItem]()

        connectionItems.append(PrivacyViewItem(iconName: "ETH", title: "Ethereum", value: interactor.ethereumConnection.title, changable: true))

        connectionItems.append(contentsOf: [
            PrivacyViewItem(iconName: "EOS", title: "EOS", value: "eos.greymass.com", changable: false),
            PrivacyViewItem(iconName: "BNB", title: "Binance", value: "dex.binance.com", changable: false)
        ])

        view?.set(connectionItems: connectionItems)
    }

    private func updateSync() {
        view?.set(syncModeItems: factory.syncViewItems(items: syncItems))
    }

}

extension PrivacyPresenter: IPrivacyViewDelegate {

    func onLoad() {
        updateSortMode()

        updateConnection()

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
        switch index {
        case 0:
            let selectedSettingName = interactor.ethereumConnection.title
            let allSettings = EthereumRpcMode.allCases.map { $0.title }

            view?.showConnectionModeAlert(itemIndex: index, title: "Ethereum", selected: selectedSettingName, all: allSettings)
        default: return
        }
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

    func onSelectConnectionSetting(itemIndex: Int, settingIndex: Int) {
        switch itemIndex {
        case 0:
            let newSetting = EthereumRpcMode.allCases[settingIndex]
            interactor.save(connectionSetting: newSetting)

            updateConnection()
            view?.updateUI()
        default: return
        }
    }

    func onSelectSortSetting(settingIndex: Int) {
        interactor.save(sortSetting: TransactionDataSortMode.allCases[settingIndex])

        updateSortMode()
        view?.updateUI()
    }

}

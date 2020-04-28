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
        router.showSortMode(currentSortMode: interactor.sortMode, delegate: self)
    }

    func onSelectConnection(index: Int) {
        switch index {
        case 0:
            let selectedSetting = interactor.ethereumConnection
            let allSettings = EthereumRpcMode.allCases

            view?.showConnectionModeAlert(itemIndex: index, coinName: "Ethereum", iconName: "ETH", items: factory.ethConnectionSelectViewItems(currentSetting: selectedSetting, all: allSettings))
        default: return
        }
    }

    func onSelectSync(index: Int) {
        let currentSetting = syncItems[index]

        let coinName: String = currentSetting.coin.title
        let iconName: String = currentSetting.coin.code

        view?.showSyncModeAlert(itemIndex: index, coinName: coinName, iconName: iconName, items: factory.syncSelectViewItems(currentSetting: currentSetting, all: syncModes))
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

}

extension PrivacyPresenter: IPrivacySortModeDelegate {

    func onSelect(sortMode: TransactionDataSortMode) {
        interactor.save(sortSetting: sortMode)

        updateSortMode()
        view?.updateUI()
    }

}

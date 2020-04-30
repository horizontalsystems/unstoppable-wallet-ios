class PrivacyPresenter {
    weak var view: IPrivacyView?

    private let interactor: IPrivacyInteractor
    private let router: IPrivacyRouter
    private let factory = PrivacyViewItemFactory()

    private var syncItems = [PrivacySyncItem]()

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

    private var standardCreatedWalletExists: Bool {
        interactor.wallets.contains { wallet in
            wallet.account.origin == .created && wallet.coin.type.predefinedAccountType == .standard
        }
    }

}

extension PrivacyPresenter: IPrivacyViewDelegate {

    func onLoad() {
        updateSortMode()

        updateConnection()

        if !standardCreatedWalletExists {
            syncItems = interactor.syncSettings.compactMap {(setting, coins) in
                guard let coin = coins.first else {
                    return nil
                }

                return PrivacySyncItem(coin: coin, setting: setting)
            }

            updateSync()
        }

        view?.updateUI()
    }

    func onSelectSortMode() {
        router.showSortMode(currentSortMode: interactor.sortMode, delegate: self)
    }

    func onSelectConnection(index: Int) {
        switch index {
        case 0:
            router.showEthereumRpcMode(currentMode: interactor.ethereumConnection, delegate: self)
        default:
            return
        }
    }

    func onSelectSync(index: Int) {
        let currentSetting = syncItems[index]
        router.showSyncMode(coin: currentSetting.coin, currentSyncMode: currentSetting.setting.syncMode, delegate: self)
    }

}

extension PrivacyPresenter: IPrivacySortModeDelegate {

    func onSelect(sortMode: TransactionDataSortMode) {
        interactor.save(sortSetting: sortMode)

        updateSortMode()
        view?.updateUI()
    }

}

extension PrivacyPresenter: IPrivacyEthereumRpcModeDelegate {

    func onSelect(mode: EthereumRpcMode) {
        interactor.save(connectionSetting: mode)

        updateConnection()
        view?.updateUI()
    }

}

extension PrivacyPresenter: IPrivacySyncModeDelegate {

    func onSelect(syncMode: SyncMode, coin: Coin) {
        let newSetting = InitialSyncSetting(coinType: coin.type, syncMode: syncMode)

        if let index = syncItems.firstIndex(where: { $0.coin == coin }) {
            syncItems[index].setting = newSetting
        }

        interactor.save(syncSetting: newSetting)

        updateSync()
        view?.updateUI()
    }

}

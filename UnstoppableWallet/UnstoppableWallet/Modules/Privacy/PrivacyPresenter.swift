import MarketKit

class PrivacyPresenter {
    weak var view: IPrivacyView?

    private let interactor: IPrivacyInteractor
    private let router: IPrivacyRouter

    private var syncItems = [PrivacySyncItem]()

    init(interactor: IPrivacyInteractor, router: IPrivacyRouter) {
        self.interactor = interactor
        self.router = router
    }

    private func updateSortMode() {
        view?.set(sortMode: interactor.sortMode.title)
    }

    private func updateSync() {
        let viewItems = syncItems.map { item in
            PrivacyViewItem(iconName: iconName(coinType: item.setting.coinType), title: title(coinType: item.setting.coinType), value: item.setting.syncMode.title, changeable: item.changeable)
        }
        view?.set(syncModeItems: viewItems)
    }

    private var isActiveAccountCreated: Bool {
        guard let account = interactor.activeAccount else {
            return false
        }

        return account.origin == .created
    }

    private func title(coinType: CoinType) -> String {
        switch coinType {
        case .bitcoin: return "Bitcoin"
        case .bitcoinCash: return "Bitcoin Cash"
        case .litecoin: return "Litecoin"
        case .dash: return "Dash"
        default: return ""
        }
    }

    private func iconName(coinType: CoinType) -> String {
        switch coinType {
        case .bitcoin: return "bitcoin_24"
        case .bitcoinCash: return "bitcoin_cash_24"
        case .litecoin: return "litecoin_24"
        case .dash: return "dash_24"
        default: return ""
        }
    }

}

extension PrivacyPresenter: IPrivacyViewDelegate {

    func onLoad() {
        updateSortMode()

        if !isActiveAccountCreated {
            syncItems = interactor.syncSettings.compactMap { setting, changeable in
                PrivacySyncItem(setting: setting, changeable: changeable)
            }

            updateSync()
        }

        view?.updateUI()
    }

    func onTapInfo() {
        router.showPrivacyInfo()
    }

    func onSelectSortMode() {
        router.showSortMode(currentSortMode: interactor.sortMode, delegate: self)
    }

    func onSelectSync(index: Int) {
        let item = syncItems[index]

        guard item.changeable else {
            return
        }

        router.showSyncMode(coinTitle: title(coinType: item.setting.coinType), coinIconName: iconName(coinType: item.setting.coinType), coinType: item.setting.coinType, currentSyncMode: item.setting.syncMode, delegate: self)
    }

}

extension PrivacyPresenter: IPrivacySortModeDelegate {

    func onSelect(sortMode: TransactionDataSortMode) {
        interactor.save(sortSetting: sortMode)

        updateSortMode()
        view?.updateUI()
    }

}

extension PrivacyPresenter: IPrivacySyncModeDelegate {

    func onSelect(syncMode: SyncMode, coinType: CoinType) {
        let newSetting = InitialSyncSetting(coinType: coinType, syncMode: syncMode)

        if let index = syncItems.firstIndex(where: { $0.setting.coinType == coinType }) {
            syncItems[index].setting = newSetting
        }

        interactor.save(syncSetting: newSetting)

        updateSync()
        view?.updateUI()
    }

}

import MarketKit

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

    private func updateSync() {
        view?.set(syncModeItems: factory.syncViewItems(items: syncItems))
    }

    private var isActiveAccountCreated: Bool {
        guard let account = interactor.activeAccount else {
            return false
        }

        return account.origin == .created
    }

}

extension PrivacyPresenter: IPrivacyViewDelegate {

    func onLoad() {
        updateSortMode()

        if !isActiveAccountCreated {
            syncItems = interactor.syncSettings.compactMap { setting, platformCoin, changeable in
                PrivacySyncItem(platformCoin: platformCoin, setting: setting, changeable: changeable)
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

        router.showSyncMode(platformCoin: item.platformCoin, currentSyncMode: item.setting.syncMode, delegate: self)
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

    func onSelect(syncMode: SyncMode, platformCoin: PlatformCoin) {
        let newSetting = InitialSyncSetting(coinType: platformCoin.coinType, syncMode: syncMode)

        if let index = syncItems.firstIndex(where: { $0.platformCoin == platformCoin }) {
            syncItems[index].setting = newSetting
        }

        interactor.save(syncSetting: newSetting)

        updateSync()
        view?.updateUI()
    }

}

import MarketKit

class PrivacySyncModePresenter {
    weak var view: IPrivacySyncModeView?
    weak var delegate: IPrivacySyncModeDelegate?

    private let router: IPrivacySyncModeRouter

    private let coinTitle: String
    private let coinIconName: String
    private let coinType: CoinType
    private var currentSyncMode: SyncMode
    private let syncModes: [SyncMode] = [.fast, .slow]

    init(coinTitle: String, coinIconName: String, coinType: CoinType, currentSyncMode: SyncMode, router: IPrivacySyncModeRouter) {
        self.coinTitle = coinTitle
        self.coinIconName = coinIconName
        self.coinType = coinType
        self.currentSyncMode = currentSyncMode
        self.router = router
    }

    private func syncViewItems() {
        let viewItems = syncModes.map { syncMode in
            PrivacySyncModeModule.ViewItem(
                    title: syncMode.title,
                    subtitle: syncMode.description,
                    selected: syncMode == currentSyncMode
            )
        }
        view?.set(viewItems: viewItems)
    }

}

extension PrivacySyncModePresenter: IPrivacySyncModeViewDelegate {

    func onLoad() {
        view?.set(coinTitle: coinTitle, coinIconName: coinIconName)
        syncViewItems()
    }

    func onTapViewItem(index: Int) {
        currentSyncMode = syncModes[index]
        syncViewItems()
    }

    func onTapDone() {
        delegate?.onSelect(syncMode: currentSyncMode, coinType: coinType)
        router.close()
    }

}

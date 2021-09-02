import MarketKit

class PrivacySyncModePresenter {
    weak var view: IPrivacySyncModeView?
    weak var delegate: IPrivacySyncModeDelegate?

    private let router: IPrivacySyncModeRouter

    private let platformCoin: PlatformCoin
    private var currentSyncMode: SyncMode
    private let syncModes: [SyncMode] = [.fast, .slow]

    init(platformCoin: PlatformCoin, currentSyncMode: SyncMode, router: IPrivacySyncModeRouter) {
        self.platformCoin = platformCoin
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
        view?.set(coinTitle: platformCoin.coin.name, coinCode: platformCoin.coin.code, coinType: platformCoin.coinType)
        syncViewItems()
    }

    func onTapViewItem(index: Int) {
        currentSyncMode = syncModes[index]
        syncViewItems()
    }

    func onTapDone() {
        delegate?.onSelect(syncMode: currentSyncMode, platformCoin: platformCoin)
        router.close()
    }

}

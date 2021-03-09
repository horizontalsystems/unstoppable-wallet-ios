import CoinKit

class PrivacySyncModePresenter {
    weak var view: IPrivacySyncModeView?
    weak var delegate: IPrivacySyncModeDelegate?

    private let router: IPrivacySyncModeRouter

    private let coin: Coin
    private var currentSyncMode: SyncMode
    private let syncModes: [SyncMode] = [.fast, .slow]

    init(coin: Coin, currentSyncMode: SyncMode, router: IPrivacySyncModeRouter) {
        self.coin = coin
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
        view?.set(coinTitle: coin.title, coinCode: coin.code, coinType: coin.type)
        syncViewItems()
    }

    func onTapViewItem(index: Int) {
        currentSyncMode = syncModes[index]
        syncViewItems()
    }

    func onTapDone() {
        delegate?.onSelect(syncMode: currentSyncMode, coin: coin)
        router.close()
    }

}

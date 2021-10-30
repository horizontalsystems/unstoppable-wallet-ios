import MarketKit

protocol IPrivacyRouter {
    func showSortMode(currentSortMode: TransactionDataSortMode, delegate: IPrivacySortModeDelegate)
    func showSyncMode(coinTitle: String, coinIconName: String, coinType: CoinType, currentSyncMode: SyncMode, delegate: IPrivacySyncModeDelegate)
    func showPrivacyInfo()
}

protocol IPrivacyInteractor {
    var activeAccount: Account? { get }
    var syncSettings: [(setting: InitialSyncSetting, changeable: Bool)] { get }
    var sortMode: TransactionDataSortMode { get }
    func save(syncSetting: InitialSyncSetting)
    func save(sortSetting: TransactionDataSortMode)
}

protocol IPrivacyView: AnyObject {
    func updateUI()
    func set(sortMode: String)
    func set(syncModeItems: [PrivacyViewItem])
}

protocol IPrivacyViewDelegate {
    func onLoad()
    func onTapInfo()
    func onSelectSortMode()
    func onSelectSync(index: Int)
}

import CoinKit

protocol IPrivacyRouter {
    func showSortMode(currentSortMode: TransactionDataSortMode, delegate: IPrivacySortModeDelegate)
    func showEthereumRpcMode(currentMode: EthereumRpcMode, delegate: IPrivacyEthereumRpcModeDelegate)
    func showSyncMode(coin: Coin, currentSyncMode: SyncMode, delegate: IPrivacySyncModeDelegate)
    func showPrivacyInfo()
}

protocol IPrivacyInteractor {
    var activeAccount: Account? { get }
    var syncSettings: [(setting: InitialSyncSetting, coin: Coin, changeable: Bool)] { get }
    var sortMode: TransactionDataSortMode { get }
    var ethereumConnection: EthereumRpcMode { get }
    func save(syncSetting: InitialSyncSetting)
    func save(connectionSetting: EthereumRpcMode)
    func save(sortSetting: TransactionDataSortMode)
}

protocol IPrivacyView: AnyObject {
    func updateUI()
    func set(sortMode: String)
    func set(connectionItems: [PrivacyViewItem])
    func set(syncModeItems: [PrivacyViewItem])
}

protocol IPrivacyViewDelegate {
    func onLoad()
    func onTapInfo()
    func onSelectSortMode()
    func onSelectConnection(index: Int)
    func onSelectSync(index: Int)
}

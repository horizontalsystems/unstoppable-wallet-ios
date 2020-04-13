protocol IPrivacyRouter {

}

protocol IPrivacyInteractor {
    var syncSettings: [(setting: InitialSyncSetting, coins: [Coin])] { get }
    var sortMode: TransactionDataSortMode { get }
    var ethereumConnection: EthereumRpcMode { get }
    func save(syncSetting: InitialSyncSetting)
    func save(connectionSetting: EthereumRpcMode)
    func save(sortSetting: TransactionDataSortMode)
}

protocol IPrivacyView: class {
    func updateUI()
    func set(sortMode: String)
    func set(connectionItems: [PrivacyViewItem])
    func set(syncModeItems: [PrivacyViewItem])
    func showSyncModeAlert(itemIndex: Int, coinName: String, selected: String, all: [String])
    func showConnectionModeAlert(itemIndex: Int, title: String, selected: String, all: [String])
    func showSortModeAlert(selected: String, all: [String])
}

protocol IPrivacyViewDelegate {
    func onLoad()
    func onSelectSortMode()
    func onSelectConnection(index: Int)
    func onSelectSync(index: Int)
    func onSelectSyncSetting(itemIndex: Int, settingIndex: Int)
    func onSelectConnectionSetting(itemIndex: Int, settingIndex: Int)
    func onSelectSortSetting(settingIndex: Int)
}

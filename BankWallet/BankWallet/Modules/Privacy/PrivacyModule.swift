protocol IPrivacyRouter {

}

protocol IPrivacyInteractor {
    var syncSettings: [(setting: InitialSyncSetting, coins: [Coin])] { get }
    func save(syncSetting: InitialSyncSetting)
}

protocol IPrivacyView: class {
    func updateUI()
    func set(sortingMode: String)
    func set(connectionItems: [PrivacyViewItem])
    func set(syncModeItems: [PrivacyViewItem])
    func showSyncModeAlert(itemIndex: Int, coinName: String, selected: String, all: [String])
}

protocol IPrivacyViewDelegate {
    func onLoad()
    func onSelectSortMode()
    func onSelectConnection(index: Int)
    func onSelectSync(index: Int)
    func onSelectSyncSetting(itemIndex: Int, settingIndex: Int)
}

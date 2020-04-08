protocol IPrivacyRouter {

}

protocol IPrivacyInteractor {

}

protocol IPrivacyView: class {
    func updateUI()
    func set(sortingMode: String)
    func set(connectionItems: [PrivacyViewItem])
    func set(syncModeItems: [PrivacyViewItem])
}

protocol IPrivacyViewDelegate {
    func onLoad()
    func onSelectSortMode()
    func onSelectConnection(index: Int)
    func onSelectSync(index: Int)
}

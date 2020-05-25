protocol IPrivacySortModeView: AnyObject {
    func set(viewItems: [PrivacySortModeModule.ViewItem])
}

protocol IPrivacySortModeViewDelegate {
    func onLoad()
    func onTapViewItem(index: Int)
    func onTapDone()
}

protocol IPrivacySortModeRouter {
    func close()
}

protocol IPrivacySortModeDelegate: AnyObject {
    func onSelect(sortMode: TransactionDataSortMode)
}

class PrivacySortModeModule {

    struct ViewItem {
        let title: String
        let subtitle: String
        let selected: Bool
    }

}

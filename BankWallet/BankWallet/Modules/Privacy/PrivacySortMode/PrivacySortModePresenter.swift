class PrivacySortModePresenter {
    weak var view: IPrivacySortModeView?
    weak var delegate: IPrivacySortModeDelegate?

    private let router: IPrivacySortModeRouter

    private var currentSortMode: TransactionDataSortMode
    private let sortModes = TransactionDataSortMode.allCases

    init(currentSortMode: TransactionDataSortMode, router: IPrivacySortModeRouter) {
        self.currentSortMode = currentSortMode
        self.router = router
    }

    private func syncViewItems() {
        let viewItems = sortModes.map { sortMode in
            PrivacySortModeModule.ViewItem(
                    title: sortMode.title,
                    subtitle: sortMode.description,
                    selected: sortMode == currentSortMode
            )
        }
        view?.set(viewItems: viewItems)
    }

}

extension PrivacySortModePresenter: IPrivacySortModeViewDelegate {

    func onLoad() {
        syncViewItems()
    }

    func onTapViewItem(index: Int) {
        currentSortMode = sortModes[index]
        syncViewItems()
    }

    func onTapDone() {
        delegate?.onSelect(sortMode: currentSortMode)
        router.close()
    }

}

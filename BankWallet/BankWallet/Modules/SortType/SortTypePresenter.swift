class SortTypePresenter {
    weak var view: IAlertView?

    private let interactor: ISortTypeInteractor
    private let router: IAlertRouter

    private let sortTypes = SortType.allCases

    init(interactor: ISortTypeInteractor, router: IAlertRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension SortTypePresenter: IAlertViewDelegate {

    func onLoad() {
        let currentSortType = interactor.sortType

        let viewItems = sortTypes.map { sortType in
            AlertViewItem(text: sortType.title, selected: sortType == currentSortType)
        }

        view?.set(viewItems: viewItems)
    }

    func onTapViewItem(index: Int) {
        interactor.sortType = sortTypes[index]
        router.close()
    }

}

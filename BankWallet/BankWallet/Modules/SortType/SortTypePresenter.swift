class SortTypePresenter {
    private let router: ISortTypeRouter
    private let interactor: ISortTypeInteractor

    private var sort: BalanceSortType

    weak var view: IAlertViewController?

    init(router: ISortTypeRouter, interactor: ISortTypeInteractor, sort: BalanceSortType) {
        self.router = router
        self.interactor = interactor
        self.sort = sort
    }

}

extension SortTypePresenter: IAlertViewDelegate {
    var items: [AlertItem] {
        return [
            .header("balance.sort.header"),
            .row("balance.sort.valueHighToLow"),
            .row("balance.sort.az"),
            .row("balance.sort.24h_change"),
        ]
    }

    func onDidLoad(alert: IAlertViewController) {
        view?.setSelected(index: sort.rawValue)
    }

    func onSelect(alert: IAlertViewController, index: Int) {
        view?.setSelected(index: index)

        let selectedSort = BalanceSortType(rawValue: index) ?? .name
        if selectedSort != .percentGrowth {
            interactor.set(sort: selectedSort)
        }
        router.dismiss(with: selectedSort)
    }

}

extension SortTypePresenter: ISortTypeInteractorDelegate {
}

class SortTypePresenter {
    private let router: ISortTypeRouter
    private let interactor: ISortTypeInteractor

    private var sort: BalanceSortType

    weak var view: IAlertView?

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
        ]
    }

    func onDidLoad() {
        view?.setSelected(index: sort.rawValue)
    }

    func onSelect(index: Int) {
        view?.setSelected(index: index)

        let selectedSort = BalanceSortType(rawValue: index) ?? .name
        interactor.set(sort: selectedSort)
        router.dismiss(with: selectedSort)
    }

}

extension SortTypePresenter: ISortTypeInteractorDelegate {
}

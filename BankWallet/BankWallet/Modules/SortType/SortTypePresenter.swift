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

    private func convert(index: Int) -> BalanceSortType {
        return BalanceSortType(rawValue: index) ?? .manual
    }

    private func convert(type: BalanceSortType) -> Int {
        return type.rawValue
    }

}

extension SortTypePresenter: IAlertViewDelegate {

    func onDidLoad(_ delegate: IAlertView) {
        view = delegate

        view?.addHeader(title: "balance.sort.header")
        view?.addRow(title: "balance.sort.valueHighToLow")
//        view?.addRow(title: "balance.sort.valueLowToHigh")
        view?.addRow(title: "balance.sort.az")
//        view?.addRow(title: "balance.sort.za")
        view?.addRow(title: "balance.sort.manual")
    }

    func onWillAppear() {
        view?.setSelected(index: convert(type: sort))
    }

    func onSelect(index: Int) {
        view?.setSelected(index: index)

        let selectedSort = convert(index: index)
        interactor.set(sort: selectedSort)
        router.dismiss(with: selectedSort)
    }

}

extension SortTypePresenter: ISortTypeInteractorDelegate {
}

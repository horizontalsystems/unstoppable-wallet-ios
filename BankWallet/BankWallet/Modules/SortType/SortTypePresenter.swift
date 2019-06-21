class SortTypePresenter {
    private let router: ISortTypeRouter
    private let interactor: ISortTypeInteractor

    private var sort: BalanceSortType

    weak var view: ISortTypeView?

    init(router: ISortTypeRouter, interactor: ISortTypeInteractor, sort: BalanceSortType) {
        self.router = router
        self.interactor = interactor
        self.sort = sort
    }

}

extension SortTypePresenter: ISortTypeViewDelegate {

    func onDidLoad() {
        view?.set(selected: sort)
    }

    func onSelect(sort: BalanceSortType) {
        view?.set(selected: sort)
        interactor.set(sort: sort)
        router.dismiss(with: sort)
    }

}

extension SortTypePresenter: ISortTypeInteractorDelegate {
}

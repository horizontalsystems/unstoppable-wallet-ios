class SortTypeInteractor {
    weak var delegate: ISortTypeInteractorDelegate?

    private let localStorage: ILocalStorage

    init(localStorage: ILocalStorage) {
        self.localStorage = localStorage
    }

}

extension SortTypeInteractor: ISortTypeInteractor {

    func set(sort: BalanceSortType) {
        localStorage.balanceSortType = sort
    }

}

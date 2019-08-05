protocol ISortTypeInteractor {
    func set(sort: BalanceSortType)
}

protocol ISortTypeInteractorDelegate: class {
}

protocol ISortTypeRouter {
    func dismiss(with sort: BalanceSortType)
}

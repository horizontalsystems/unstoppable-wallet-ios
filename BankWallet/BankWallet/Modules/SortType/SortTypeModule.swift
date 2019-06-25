protocol ISortTypeView: class {
    func set(selected type: BalanceSortType)
}

protocol ISortTypeViewDelegate {
    func onDidLoad()
    func onSelect(sort: BalanceSortType)
}

protocol ISortTypeInteractor {
    func set(sort: BalanceSortType)
}

protocol ISortTypeInteractorDelegate: class {
}

protocol ISortTypeRouter {
    func dismiss(with sort: BalanceSortType)
}

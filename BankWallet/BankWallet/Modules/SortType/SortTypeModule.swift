protocol ISortTypeInteractor: AnyObject {
    var sortType: SortType { get set }
}

protocol ISortTypeRouter {
    func close()
}

class SortTypeInteractor {
    private let sortTypeManager: ISortTypeManager

    init(sortTypeManager: ISortTypeManager) {
        self.sortTypeManager = sortTypeManager
    }

}

extension SortTypeInteractor: ISortTypeInteractor {

    var sortType: SortType {
        get {
            sortTypeManager.sortType
        }
        set {
            sortTypeManager.sortType = newValue
        }
    }

}

import RxSwift

class SortTypeManager {
    private let localStorage: ILocalStorage

    private let subject = PublishSubject<SortType>()

    init(localStorage: ILocalStorage) {
        self.localStorage = localStorage
    }

}

extension SortTypeManager: ISortTypeManager {

    var sortType: SortType {
        get {
            localStorage.sortType ?? .name
        }
        set {
            localStorage.sortType = newValue
            subject.onNext(newValue)
        }
    }

    var sortTypeObservable: Observable<SortType> {
        subject.asObservable()
    }

}
